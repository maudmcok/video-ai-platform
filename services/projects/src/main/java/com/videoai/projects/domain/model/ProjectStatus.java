package com.videoai.projects.domain.model;

import java.util.Set;

public enum ProjectStatus {
    CREATED,
    INGESTED,
    PROCESSING,
    RENDERING,
    READY,
    FAILED;

    private static final Set<ProjectStatus> TERMINAL_STATES = Set.of(READY, FAILED);

    public boolean isTerminal() {
        return TERMINAL_STATES.contains(this);
    }

    public boolean canTransitionTo(ProjectStatus target) {
        if (this.isTerminal()) return false;

        return switch (this) {
            case CREATED -> target == INGESTED || target == FAILED;
            case INGESTED -> target == PROCESSING || target == FAILED;
            case PROCESSING -> target == RENDERING || target == FAILED;
            case RENDERING -> target == READY || target == FAILED;
            default -> false;
        };
    }
}
