extern float example_number;
extern vec3 example_vec3;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec4 tex = Texel(texture, texture_coords);

    tex.g *= example_number;
    tex.rgb *= example_vec3;

    return tex;
}