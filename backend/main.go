package main

import (
	"log"
	"net/http"
	"sync"
	"github.com/gorilla/websocket"
)

var (
	upgrader = websocket.Upgrader{CheckOrigin: func(r *http.Request) bool { return true }}
	peers    = make(map[*websocket.Conn]bool)
	peersMux sync.Mutex
)

func handleConnections(w http.ResponseWriter, r *http.Request) {
	conn, _ := upgrader.Upgrade(w, r, nil)
	defer func() {
		peersMux.Lock()
		delete(peers, conn)
		peersMux.Unlock()
		conn.Close()
	}()

	peersMux.Lock()
	peers[conn] = true
	peersMux.Unlock()

	for {
		var msg map[string]interface{}
		if err := conn.ReadJSON(&msg); err != nil {
			log.Println("Read error:", err)
			break
		}

		// Broadcast to all other peers
		peersMux.Lock()
		for peer := range peers {
			if peer != conn {
				if err := peer.WriteJSON(msg); err != nil {
					log.Println("Write error:", err)
				}
			}
		}
		peersMux.Unlock()
	}
}