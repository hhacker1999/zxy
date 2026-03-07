package zxyWs

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
)

type Message struct {
	Type    string          `json:"type"`
	Data    json.RawMessage `json:"data"`
	UserId  int
	Profile int
}

type MessageHandler = func(message Message)

type ClientInfo struct {
	conn            *websocket.Conn
	writeMutex      *sync.Mutex
	userId          int
	profileId       int
	incomingChannel chan []byte
	closeChan       chan struct{}
	isStale         atomic.Bool
}

type WSHandler struct {
	messageHandlers   map[string]MessageHandler
	clientConnections map[string]*ClientInfo
	upgrader          websocket.Upgrader
	mtx               *sync.RWMutex
	onExitProcedure   atomic.Bool
}

func New() *WSHandler {
	upgrader := websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}
	handler := &WSHandler{
		messageHandlers:   make(map[string]MessageHandler),
		clientConnections: make(map[string]*ClientInfo),
		upgrader:          upgrader,
		mtx:               &sync.RWMutex{},
	}
	go handler.removeStaleConnections()
	return handler
}

func (h *WSHandler) RegisterMessageHandler(msgType []string, handler MessageHandler) {
	for _, v := range msgType {
		h.messageHandlers[v] = handler
	}
}

func (h *WSHandler) HandleClientConnectionRequest(w http.ResponseWriter, r *http.Request) {
	if h.onExitProcedure.Load() {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	conn, err := h.upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Println("Error upgrading:", err)
		return
	}

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)
	// userId := 0
	// profileId := 0

	key := fmt.Sprintf("%d:%d", userId, profileId)
	h.mtx.Lock()
	oldClient, ok := h.clientConnections[key]
	if ok {
		fmt.Println("Old connection found for same user ", userId, profileId)
		select {
		case oldClient.closeChan <- struct{}{}:
		default:
		}
	}
	client := &ClientInfo{
		conn:            conn,
		writeMutex:      &sync.Mutex{},
		userId:          userId,
		profileId:       profileId,
		incomingChannel: make(chan []byte, 20),
		closeChan:       make(chan struct{}, 1),
	}
	h.clientConnections[key] = client
	fmt.Println("Total socket connections currently are ", len(h.clientConnections))
	h.mtx.Unlock()
	conn.SetReadLimit(512 * 1024)

	go h.handleSingleClient(client)
	go h.listenForMessages(client)

}

func (h *WSHandler) listenForMessages(client *ClientInfo) {
	for {
		_, message, err := client.conn.ReadMessage()
		if err != nil {
			fmt.Println("Error reading message:", err)
			select {
			case client.closeChan <- struct{}{}:
			default:
			}
			return
		}
		select {
		case client.incomingChannel <- message:
		case <-client.closeChan:
			return
		}
	}
}

func (h *WSHandler) handleSingleClient(info *ClientInfo) {
	clientKey := fmt.Sprintf("%d:%d", info.userId, info.profileId)
	pingTicker := time.NewTicker(time.Second * 2)
	defer pingTicker.Stop()
	lastPingTime := time.Now()
	once := &sync.Once{}
	closeConn := func() {
		once.Do(func() {
			info.isStale.Store(true)
			info.conn.Close()
		})
	}

	for {
		select {
		case <-pingTicker.C:
			if time.Now().Sub(lastPingTime) > (time.Second * 10) {
				fmt.Println("Ping not received from client, closing connection for ", clientKey)
				closeConn()
				return
			}
		case message := <-info.incomingChannel:
			// fmt.Printf("Raw bytes: %v | String: %s\n", message, string(message))
			if string(message) == "ping" {
				lastPingTime = time.Now()
				info.writeMutex.Lock()
				err := info.conn.WriteMessage(websocket.TextMessage, []byte("pong"))
				if err != nil {
					fmt.Println("Error writing message:", err)
					info.writeMutex.Unlock()
					closeConn()
					return
				}
				info.writeMutex.Unlock()
			} else {
				var msg Message
				err := json.Unmarshal(message, &msg)
				if err != nil {
					fmt.Println("Error unmarshalling client message: ", string(message), err)
					continue
				}
				handler, ok := h.messageHandlers[msg.Type]
				if !ok {
					fmt.Println("No handler for type", msg.Type)
					continue
				}
				// NOTE: Our message handler, could be any usecase who registers himself as a handler for
				// this type of message
				msg.UserId = info.userId
				msg.Profile = info.profileId
				go handler(msg)
			}
		case <-info.closeChan:
			closeConn()
			return
		}
	}

}

func (h *WSHandler) SendMessage(userId int, profileId int, message []byte) error {
	key := fmt.Sprintf("%d:%d", userId, profileId)
	h.mtx.RLock()
	client, ok := h.clientConnections[key]
	h.mtx.RUnlock()

	if !ok || client.isStale.Load() {
		return fmt.Errorf("Client is currently not connected")
	}
	client.writeMutex.Lock()
	defer client.writeMutex.Unlock()
	err := client.conn.WriteMessage(websocket.TextMessage, message)
	if err != nil {
		fmt.Println("Error sending message ", err)
		select {
		case client.closeChan <- struct{}{}:
		default:
		}
		return err
	}

	return nil
}

func (h *WSHandler) removeStaleConnections() {
	for {
		time.Sleep(time.Minute * 1)
		h.mtx.Lock()
		fmt.Println("Removing stale connections ", len(h.clientConnections))
		for k, v := range h.clientConnections {
			if v.isStale.Load() {
				delete(h.clientConnections, k)
			}
		}
		fmt.Println(
			"Removed stale connections now current connections are ",
			len(h.clientConnections),
		)
		h.mtx.Unlock()
	}
}

func (h *WSHandler) Close() {
	h.onExitProcedure.Store(true)
	for _, v := range h.clientConnections {
		select {
		case v.closeChan <- struct{}{}:
		default:
		}
	}
}
