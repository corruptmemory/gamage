#version 330

// Input vertex attributes (from vertex shader)
in vec2 fragTexCoord;
in vec4 fragColor;
in vec3 fragPosition;
in vec3 fragNormal;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;
uniform vec3 lightPos;
uniform vec3 lightColor = vec3(0.3, 0.3, 0.3);

// Output fragment color
out vec4 finalColor;

// NOTE: Add here your custom variables

void main() {
	vec3 normal = normalize(fragNormal);
	vec3 light = normalize(lightPos - fragPosition);
	float diff = max(dot(normal, light), 0.0);
	vec3 diffuse = diff * lightColor;

    // Texel color fetching from texture sampler
    vec4 texelColor = texture(texture0, fragTexCoord);

    // NOTE: Implement here your fragment shader code

    finalColor = texelColor*(colDiffuse+vec4(diffuse,0.0))*fragColor;
    // finalColor = texelColor*(vec4(diffuse,0.0))*fragColor;
}

