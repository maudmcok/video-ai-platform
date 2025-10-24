package com.videoai.projects.domain.model;

import com.fasterxml.jackson.annotation.JsonSubTypes;
import com.fasterxml.jackson.annotation.JsonTypeInfo;

@JsonTypeInfo(use = JsonTypeInfo.Id.NAME, property = "type")
@JsonSubTypes({
    @JsonSubTypes.Type(value = AnalyzeVideoConfig.class, name = "ANALYZE_VIDEO"),
    @JsonSubTypes.Type(value = Text2VideoConfig.class, name = "TEXT2VIDEO"),
    @JsonSubTypes.Type(value = FusionConfig.class, name = "FUSION")
})
public sealed interface ProjectConfig permits AnalyzeVideoConfig, Text2VideoConfig, FusionConfig {
    void validate();
}
