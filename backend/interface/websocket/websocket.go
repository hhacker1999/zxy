package zxyWs

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
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

type WSHandler struct {
	messageHandlers   map[string]MessageHandler
	clientConnections map[string]*websocket.Conn
	upgrader          websocket.Upgrader
	mtx               *sync.RWMutex
}

func New() *WSHandler {
	upgrader := websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}
	return &WSHandler{
		messageHandlers:   make(map[string]MessageHandler),
		clientConnections: make(map[string]*websocket.Conn),
		upgrader:          upgrader,
		mtx:               &sync.RWMutex{},
	}
}

func (h *WSHandler) RegisterMessageHandler(msgType []string, handler MessageHandler) {
	for _, v := range msgType {
		h.messageHandlers[v] = handler
	}
}

func (h *WSHandler) HandleClientConnectionRequest(w http.ResponseWriter, r *http.Request) {
	conn, err := h.upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Println("Error upgrading:", err)
		return
	}

	userId := r.Context().Value("user_id").(int)
	profileId := r.Context().Value("profile_id").(int)

	h.mtx.Lock()
	key := fmt.Sprintf("%d:%d", userId, profileId)
	oldConn, ok := h.clientConnections[key]
	if ok {
		fmt.Println("Old connection found for same user ", userId, profileId)
		err := oldConn.Close()
		if err != nil {
			fmt.Println("Erorr closing old client connection", err)
		}
	}
	h.clientConnections[key] = conn
	conn.SetReadLimit(512 * 1024)

	fmt.Println("Total socket connections currently are ", len(h.clientConnections))
	go h.listenForClientMessages(userId, profileId, conn)
	defer h.mtx.Unlock()

}

func (h *WSHandler) listenForClientMessages(userId int, profileId int, conn *websocket.Conn) {
	clientKey := fmt.Sprintf("%d:%d", userId, profileId)
	pingTicker := time.NewTicker(time.Second * 1)
	defer pingTicker.Stop()
	lastPingTime := time.Now()

	closeConn := func() {
		h.mtx.Lock()
		conn.Close()
		delete(h.clientConnections, clientKey)
		h.mtx.Unlock()
	}

	for {
		select {
		case <-pingTicker.C:
			if time.Now().Sub(lastPingTime) > (time.Second * 1) {
				fmt.Println("Ping not received from client, closing connection for ", clientKey)
				closeConn()
				return
			}
		default:
			_, message, err := conn.ReadMessage()
			if err != nil {
				fmt.Println("Error reading message:", err)
				break
			}
			if string(message) == "ping" {
				lastPingTime = time.Now()
				err := conn.WriteMessage(websocket.TextMessage, []byte("pong"))
				if err != nil {
					fmt.Println("Error writing message:", err)
					closeConn()
					return
				}
			} else {
				var msg Message
				err = json.Unmarshal(message, &msg)
				if err != nil {
					fmt.Println("Error unmarshalling client message: ", string(message), err)
					continue
				}
				handler, ok := h.messageHandlers[msg.Type]
				if !ok {
					fmt.Println("No handler for type", msg.Type)
				}
				// NOTE: Our message handler, could be any usecase who registers himself as a handler for
				// this type of message
				msg.UserId = userId
				msg.Profile = profileId
				go handler(msg)
			}
		}
	}

}

func (h *WSHandler) SendMessage(userId int, profileId int, message []byte) error {
	h.mtx.RLock()
	key := fmt.Sprintf("%d:%d", userId, profileId)
	conn, ok := h.clientConnections[key]
	h.mtx.RUnlock()

	if !ok {
		return fmt.Errorf("Client is currently not connected")
	}
	err := conn.WriteMessage(websocket.BinaryMessage, message)
	if err != nil {
		fmt.Println("Error sending message ", err)
		h.mtx.Lock()
		conn.Close()
		delete(h.clientConnections, key)
		h.mtx.Unlock()
		return err
	}

	return nil
}

func (h *WSHandler) Close() {
	wg := &sync.WaitGroup{}
	for _, v := range h.clientConnections {
		wg.Add(1)
		go func() {
			defer wg.Done()
			v.Close()
		}()
	}

	wg.Wait()
}
