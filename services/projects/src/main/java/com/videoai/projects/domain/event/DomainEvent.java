package com.videoai.projects.domain.event;

import com.videoai.projects.domain.model.ProjectId;

import java.time.Instant;

public interface DomainEvent {
    ProjectId aggregateId();
    Instant occurredAt();
}
