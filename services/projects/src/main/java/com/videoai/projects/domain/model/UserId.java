package com.videoai.projects.domain.model;

import java.util.UUID;

public record UserId(UUID value) {

    public static UserId generate() {
        return new UserId(UUID.randomUUID());
    }

    public static UserId of(UUID uuid) {
        return new UserId(uuid);
    }

    public static UserId fromString(String id) {
        return new UserId(UUID.fromString(id));
    }

    @Override
    public String toString() {
        return value.toString();
    }
}
