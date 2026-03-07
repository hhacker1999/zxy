package rest

import (
	"fmt"
	"net/http"
)

const success = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Authenticated with Trakt</title>
    <style>
        :root {
            --trakt-red: #ed1c24;
            --bg-dark: #1a1a1a;
            --card-dark: #262626;
            --text-main: #ffffff;
            --text-secondary: #999999;
        }

        body {
            background-color: var(--bg-dark);
            color: var(--text-main);
            font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            text-align: center;
        }

        .container {
            background-color: var(--card-dark);
            padding: 40px;
            border-radius: 8px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
            max-width: 400px;
            width: 90%;
            border-top: 4px solid var(--trakt-red);
        }

        .icon-success {
            font-size: 50px;
            color: var(--trakt-red);
            margin-bottom: 20px;
        }

        h1 {
            font-size: 22px;
            margin: 0 0 10px 0;
            text-transform: uppercase;
            letter-spacing: 1px;
        }

        p {
            color: var(--text-secondary);
            font-size: 16px;
            line-height: 1.5;
            margin-bottom: 30px;
        }

        .timer-box {
            font-size: 14px;
            color: var(--text-secondary);
            border-top: 1px solid #333;
            padding-top: 20px;
        }

        #countdown {
            color: var(--trakt-red);
            font-weight: bold;
            font-size: 18px;
        }

        .btn-manual {
            display: inline-block;
            margin-top: 15px;
            color: var(--trakt-red);
            text-decoration: none;
            font-size: 12px;
            text-transform: uppercase;
            font-weight: bold;
            letter-spacing: 1px;
        }
    </style>
</head>
<body>

    <div class="container">
        <div class="icon-success">✓</div>
        <h1>Authenticated</h1>
        <p>Your Trakt account was linked successfully. You can now return to the app.</p>
        
        <div class="timer-box">
            Closing this tab in <span id="countdown">5</span> seconds...
        </div>
        
        <a href="#" class="btn-manual" onclick="window.close()">Close Now</a>
    </div>

    <script>
        let timeLeft = 5;
        const countdownElement = document.getElementById('countdown');

        const timer = setInterval(() => {
            timeLeft--;
            countdownElement.textContent = timeLeft;
            
            if (timeLeft <= 0) {
                clearInterval(timer);
                window.close();
                // Fallback if window.close() is blocked by browser
                document.querySelector('.timer-box').textContent = "You can safely close this window.";
            }
        }, 1000);
    </script>

</body>
</html>/html>
  `

const failed = `
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Authentication Failed</title>
    <style>
        :root {
            --trakt-error: #ed1c24; 
            --bg-dark: #1a1a1a;
            --card-dark: #262626;
            --text-main: #ffffff;
            --text-secondary: #999999;
        }

        body {
            background-color: var(--bg-dark);
            color: var(--text-main);
            font-family: "Helvetica Neue", Helvetica, Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            text-align: center;
        }

        .container {
            background-color: var(--card-dark);
            padding: 50px 30px;
            border-radius: 8px;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
            max-width: 350px;
            width: 85%;
            border-bottom: 4px solid var(--trakt-error);
        }

        .icon-error {
            font-size: 40px;
            color: var(--trakt-error);
            margin-bottom: 15px;
            font-weight: bold;
        }

        h1 {
            font-size: 20px;
            margin: 0 0 10px 0;
            text-transform: uppercase;
            letter-spacing: 1.5px;
        }

        p {
            color: var(--text-secondary);
            font-size: 15px;
            line-height: 1.4;
            margin: 0;
        }

        .close-hint {
            margin-top: 30px;
            font-size: 12px;
            color: #555;
            text-transform: uppercase;
        }
    </style>
</head>
<body>

    <div class="container">
        <div class="icon-error">!</div>
        <h1>Something Failed</h1>
        <p>Please go back to the app and try again.</p>
        
        <div class="close-hint">You may close this tab</div>
    </div>

</body>
</html>
  `

func (i *RestInterface) HandleGetTraktUrl(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)
	userId := r.Context().Value("user_id").(int)

	url, err := i.traktUC.GetTraktLoginUrl(userId, profileId)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
	response.Data = map[string]string{
		"url": url,
	}
}

func (i *RestInterface) HandleTraktRedirect(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	state := r.URL.Query().Get("state")
	code := r.URL.Query().Get("code")

	err := i.traktUC.RetrieveUserAuthToken(code, state)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		fmt.Fprint(w, failed)
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprint(w, success)
}

func (i *RestInterface) HandleTraktDelete(w http.ResponseWriter, r *http.Request) {
	response := &ApiResponse{}
	defer response.SendResponse(w)

	profileId := r.Context().Value("profile_id").(int)
	userId := r.Context().Value("user_id").(int)

	err := i.traktUC.DeleteProfileTraktLogin(userId, profileId)
	if err != nil {
		response.Error = err.Error()
		response.StatusCode = http.StatusBadRequest
		return
	}

	response.StatusCode = http.StatusOK
}
