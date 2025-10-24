package com.videoai.projects.domain.event;

import com.videoai.projects.domain.model.ProjectId;
import com.videoai.projects.domain.model.ProjectStatus;

import java.time.Instant;

public record ProjectStatusChanged(
        ProjectId aggregateId,
        ProjectStatus oldStatus,
        ProjectStatus newStatus,
        Instant occurredAt
) implements DomainEvent {

    public ProjectStatusChanged(ProjectId aggregateId, ProjectStatus oldStatus, ProjectStatus newStatus) {
        this(aggregateId, oldStatus, newStatus, Instant.now());
    }
}
