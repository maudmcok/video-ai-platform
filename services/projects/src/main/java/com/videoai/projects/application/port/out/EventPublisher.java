package com.videoai.projects.application.port.out;

import com.videoai.projects.domain.event.DomainEvent;

public interface EventPublisher {
    void publish(DomainEvent event);
}
