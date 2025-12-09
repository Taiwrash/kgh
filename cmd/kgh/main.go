package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Taiwrash/kgh/internal/config"
	"github.com/Taiwrash/kgh/internal/github"
	"github.com/Taiwrash/kgh/internal/k8s"
	"github.com/Taiwrash/kgh/internal/webhook"
)

func main() {
	log.Println("Starting GitOps Controller...")

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("FATAL: Failed to load configuration: %v", err)
	}

	log.Printf("INFO: Configuration loaded successfully")
	log.Printf("INFO: Running in-cluster: %v", cfg.InCluster)
	log.Printf("INFO: Default namespace: %s", cfg.Namespace)
	log.Printf("INFO: Server port: %d", cfg.ServerPort)

	// Create Kubernetes applier
	applier, err := k8s.NewApplier(cfg.InCluster)
	if err != nil {
		log.Fatalf("FATAL: Failed to create Kubernetes applier: %v", err)
	}
	log.Println("INFO: Kubernetes client initialized successfully")

	// Create GitHub client
	ctx := context.Background()
	githubClient := github.NewClient(ctx, cfg.GitHubToken)
	log.Println("INFO: GitHub client initialized")

	// Create webhook handler
	webhookHandler := webhook.NewHandler(applier, githubClient, cfg.WebhookSecret, cfg.Namespace)

	// Setup HTTP routes
	mux := http.NewServeMux()
	mux.Handle("/webhook", webhookHandler)
	mux.HandleFunc("/health", healthHandler)
	mux.HandleFunc("/ready", readyHandler)

	// Create HTTP server
	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", cfg.ServerPort),
		Handler:      mux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Start server in a goroutine
	go func() {
		log.Printf("INFO: Server starting on port %d...", cfg.ServerPort)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("FATAL: Server failed: %v", err)
		}
	}()

	log.Println("INFO: GitOps Controller is running")
	log.Printf("INFO: Webhook endpoint: http://localhost:%d/webhook", cfg.ServerPort)
	log.Printf("INFO: Health check: http://localhost:%d/health", cfg.ServerPort)

	// Wait for interrupt signal to gracefully shutdown the server
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("INFO: Shutting down server...")

	// Graceful shutdown with timeout
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(shutdownCtx); err != nil {
		log.Printf("ERROR: Server forced to shutdown: %v", err)
	}

	log.Println("INFO: Server stopped")
}

// healthHandler returns 200 OK if the server is running
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "OK")
}

// readyHandler returns 200 OK if the server is ready to accept requests
func readyHandler(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Ready")
}
