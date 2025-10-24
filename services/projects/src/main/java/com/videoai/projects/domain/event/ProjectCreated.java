package com.videoai.projects.domain.event;

import com.videoai.projects.domain.model.ProjectConfig;
import com.videoai.projects.domain.model.ProjectId;
import com.videoai.projects.domain.model.ProjectType;
import com.videoai.projects.domain.model.UserId;

import java.time.Instant;

public record ProjectCreated(
        ProjectId aggregateId,
        UserId ownerId,
        ProjectType type,
        ProjectConfig config,
        Instant occurredAt
) implements DomainEvent {

    public ProjectCreated(ProjectId aggregateId, UserId ownerId, ProjectType type, ProjectConfig config) {
        this(aggregateId, ownerId, type, config, Instant.now());
    }
}
