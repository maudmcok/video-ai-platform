package com.videoai.projects.domain.model;

import java.util.UUID;

public record ProjectId(UUID value) {

    public static ProjectId generate() {
        return new ProjectId(UUID.randomUUID());
    }

    public static ProjectId of(UUID uuid) {
        return new ProjectId(uuid);
    }

    public static ProjectId fromString(String id) {
        return new ProjectId(UUID.fromString(id));
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
