package com.videoai.projects.domain.exception;

public class InvalidProjectStateException extends RuntimeException {
    public InvalidProjectStateException(String message) {
        super(message);
    }
}
