package com.videoai.projects.domain.model;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;

public final class Text2VideoConfig implements ProjectConfig {
    private final String scriptText;
    private final String language;
    private final String visualStyle;
    private final int targetDuration;

    @JsonCreator
    public Text2VideoConfig(
            @JsonProperty("scriptText") String scriptText,
            @JsonProperty("language") String language,
            @JsonProperty("visualStyle") String visualStyle,
            @JsonProperty("targetDuration") int targetDuration) {
        this.scriptText = scriptText;
        this.language = language;
        this.visualStyle = visualStyle;
        this.targetDuration = targetDuration;
    }

    @Override
    public void validate() {
        if (scriptText == null || scriptText.trim().isEmpty()) {
            throw new IllegalArgumentException("Script text cannot be empty");
        }
        if (scriptText.length() > 10000) {
            throw new IllegalArgumentException("Script text too long (max 10000 characters)");
        }
        if (targetDuration < 10 || targetDuration > 300) {
            throw new IllegalArgumentException("Target duration must be between 10 and 300 seconds");
        }
    }

    public String getScriptText() {
        return scriptText;
    }

    public String getLanguage() {
        return language;
    }

    public String getVisualStyle() {
        return visualStyle;
    }

    public int getTargetDuration() {
        return targetDuration;
    }
}
