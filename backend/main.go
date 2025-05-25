// backend/main.go
package main

import (
	"log"
	"net/http"
	"github.com/gorilla/websocket"
)

func main() {
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		conn, _ := websocket.Upgrade(w, r, nil, 1024, 1024)
		defer conn.Close()
		for {
			messageType, p, err := conn.ReadMessage()
			if err != nil { break }
			log.Printf("Received: %s", p)
			conn.WriteMessage(messageType, []byte("Echo: " + string(p)))
		}
	})
	log.Fatal(http.ListenAndServe(":8080", nil))
}