package com.videoai.projects.domain.model;

import com.videoai.projects.domain.event.DomainEvent;
import com.videoai.projects.domain.event.ProjectCreated;
import com.videoai.projects.domain.event.ProjectStatusChanged;
import com.videoai.projects.domain.exception.InvalidProjectStateException;
import lombok.Getter;

import java.time.Instant;
import java.util.*;

@Getter
public class Project {
    private final ProjectId id;
    private final UserId ownerId;
    private final ProjectType type;
    private ProjectStatus status;
    private double progress;
    private final ProjectConfig config;
    private String errorMessage;
    private final Instant createdAt;
    private Instant updatedAt;
    private Instant completedAt;

    private final List<DomainEvent> domainEvents = new ArrayList<>();

    // Constructor (création)
    public Project(UserId ownerId, ProjectType type, ProjectConfig config) {
        this.id = ProjectId.generate();
        this.ownerId = Objects.requireNonNull(ownerId, "ownerId cannot be null");
        this.type = Objects.requireNonNull(type, "type cannot be null");
        this.config = Objects.requireNonNull(config, "config cannot be null");
        this.status = ProjectStatus.CREATED;
        this.progress = 0.0;
        this.createdAt = Instant.now();
        this.updatedAt = Instant.now();

        registerEvent(new ProjectCreated(id, ownerId, type, config));
    }

    // Reconstruction depuis DB
    public Project(ProjectId id, UserId ownerId, ProjectType type, ProjectStatus status,
            double progress, ProjectConfig config, String errorMessage,
            Instant createdAt, Instant updatedAt, Instant completedAt) {
        this.id = id;
        this.ownerId = ownerId;
        this.type = type;
        this.status = status;
        this.progress = progress;
        this.config = config;
        this.errorMessage = errorMessage;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
        this.completedAt = completedAt;
    }

    // Méthodes métier
    public void updateProgress(double newProgress) {
        if (newProgress < 0 || newProgress > 1.0) {
            throw new IllegalArgumentException("Progress must be between 0 and 1");
        }
        if (this.status.isTerminal()) {
            throw new InvalidProjectStateException("Cannot update progress on terminal state: " + status);
        }
        this.progress = newProgress;
        this.updatedAt = Instant.now();
    }

    public void transitionTo(ProjectStatus newStatus) {
        if (!this.status.canTransitionTo(newStatus)) {
            throw new InvalidProjectStateException(
                String.format("Invalid transition: %s -> %s", status, newStatus)
            );
        }

        ProjectStatus oldStatus = this.status;
        this.status = newStatus;
        this.updatedAt = Instant.now();

        if (newStatus == ProjectStatus.READY || newStatus == ProjectStatus.FAILED) {
            this.completedAt = Instant.now();
        }

        registerEvent(new ProjectStatusChanged(id, oldStatus, newStatus));
    }

    public void markAsFailed(String error) {
        this.errorMessage = error;
        transitionTo(ProjectStatus.FAILED);
    }

    public void validateOwnership(UserId userId) {
        if (!this.ownerId.equals(userId)) {
            throw new SecurityException("User does not own this project");
        }
    }

    private void registerEvent(DomainEvent event) {
        domainEvents.add(event);
    }

    public List<DomainEvent> pollDomainEvents() {
        List<DomainEvent> events = new ArrayList<>(domainEvents);
        domainEvents.clear();
        return events;
    }
}
