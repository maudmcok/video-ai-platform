package com.videoai.projects.domain.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;

public final class AnalyzeVideoConfig implements ProjectConfig {
    private final List<Integer> clipTargetDurations;
    private final String language;
    private final String stylePreset;
    private final boolean enableSubtitles;
    private final boolean enableAnimations;

    @JsonCreator
    public AnalyzeVideoConfig(
            @JsonProperty("clipTargetDurations") List<Integer> clipTargetDurations,
            @JsonProperty("language") String language,
            @JsonProperty("stylePreset") String stylePreset,
            @JsonProperty("enableSubtitles") boolean enableSubtitles,
            @JsonProperty("enableAnimations") boolean enableAnimations) {
        this.clipTargetDurations = clipTargetDurations;
        this.language = language;
        this.stylePreset = stylePreset;
        this.enableSubtitles = enableSubtitles;
        this.enableAnimations = enableAnimations;
    }

    @Override
    public void validate() {
        if (clipTargetDurations == null || clipTargetDurations.isEmpty()) {
            throw new IllegalArgumentException("At least one clip duration must be specified");
        }
        for (int duration : clipTargetDurations) {
            if (duration < 10 || duration > 300) {
                throw new IllegalArgumentException("Clip duration must be between 10 and 300 seconds");
            }
        }
    }

    public List<Integer> getClipTargetDurations() {
        return clipTargetDurations;
    }

    public String getLanguage() {
        return language;
    }

    public String getStylePreset() {
        return stylePreset;
    }

    public boolean isEnableSubtitles() {
        return enableSubtitles;
    }

    public boolean isEnableAnimations() {
        return enableAnimations;
    }
}
