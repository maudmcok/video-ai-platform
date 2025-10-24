package com.videoai.projects.domain.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public final class FusionConfig implements ProjectConfig {
    private final String primaryUrl;
    private final String secondaryUrl;
    private final String layout;
    private final String audioMode;

    @JsonCreator
    public FusionConfig(
            @JsonProperty("primaryUrl") String primaryUrl,
            @JsonProperty("secondaryUrl") String secondaryUrl,
            @JsonProperty("layout") String layout,
            @JsonProperty("audioMode") String audioMode) {
        this.primaryUrl = primaryUrl;
        this.secondaryUrl = secondaryUrl;
        this.layout = layout;
        this.audioMode = audioMode;
    }

    @Override
    public void validate() {
        if (primaryUrl == null || !primaryUrl.matches("^s3://[a-z0-9-]+/.*$")) {
            throw new IllegalArgumentException("Invalid primary URL");
        }
        if (secondaryUrl == null || !secondaryUrl.matches("^s3://[a-z0-9-]+/.*$")) {
            throw new IllegalArgumentException("Invalid secondary URL");
        }
    }

    public String getPrimaryUrl() {
        return primaryUrl;
    }

    public String getSecondaryUrl() {
        return secondaryUrl;
    }

    public String getLayout() {
        return layout;
    }

    public String getAudioMode() {
        return audioMode;
    }
}
