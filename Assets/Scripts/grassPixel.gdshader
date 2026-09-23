shader_type canvas_item;

uniform float pixel_size = 3.0;
uniform bool original_grass = false;
uniform sampler2D overlay_tex : repeat_enable, filter_nearest;
uniform float overlay_scale = 0.001;
uniform bool show_tufts = false;
uniform vec4 color_deep : source_color = vec4(0.2, 0.44, 0.19, 1.0);
uniform vec4 color_dark : source_color = vec4(0.3, 0.58, 0.21, 1.0);
uniform vec4 color_mid : source_color = vec4(0.4, 0.69, 0.24, 1.0);
uniform vec4 color_light : source_color = vec4(0.51, 0.78, 0.28, 1.0);
uniform vec4 color_tip : source_color = vec4(0.68, 0.88, 0.38, 1.0);
uniform float patch_scale = 60.0;
uniform float dither_strength = 0.06;
uniform float stripe_width = 43.0;
uniform float stripe_strength = 0.1;
uniform float speckle_amount = 0.012;
uniform float tuft_cell = 14.0;
uniform float tuft_density = 0.27;
uniform vec4 tuft_outline : source_color = vec4(0.13, 0.3, 0.12, 1.0);
uniform float wind_pixels = 2.0;
uniform float flower_cell = 26.0;
uniform float flower_density = 0.07;
uniform vec4 flower_white : source_color = vec4(0.97, 0.95, 0.9, 1.0);
uniform vec4 flower_yellow : source_color = vec4(1.0, 0.86, 0.3, 1.0);
uniform vec4 flower_pink : source_color = vec4(0.96, 0.6, 0.78, 1.0);
uniform vec4 flower_centre : source_color = vec4(0.98, 0.72, 0.18, 1.0);
uniform float wind_speed = 1.6;
uniform sampler2D blocker_mask : filter_nearest;
uniform vec4 mask_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool use_mask = false;

uniform bool infection_enabled = true;
uniform sampler2D infection_mask : filter_linear, repeat_disable;
uniform vec4 infection_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform bool use_infection_mask = false;
uniform vec4 inf_glow : source_color = vec4(0.72, 0.36, 0.8, 1.0);
uniform vec4 inf_goo : source_color = vec4(0.6, 0.3, 0.67, 1.0);
uniform vec4 inf_goo_light : source_color = vec4(0.88, 0.66, 0.92, 1.0);
uniform vec4 inf_pore : source_color = vec4(0.17, 0.08, 0.14, 1.0);
uniform vec4 inf_stain : source_color = vec4(0.42, 0.33, 0.45, 1.0);
uniform vec4 inf_stain_dark : source_color = vec4(0.3, 0.16, 0.33, 1.0);
uniform float crack_glow = 0.75;
uniform float crack_coverage = 0.4;
uniform float pulse_speed = 1.0;
uniform float vent_cell = 20.0;
uniform float vent_density = 0.18;
uniform float creep_speed = 0.3;
uniform float creep_reach = 0.42;
uniform float stain_strength = 0.5;

varying vec2 worldPosition;

bool is_blocked(vec2 wp) {
	if (!use_mask) {
		return false;
	}
	vec2 uv = (wp - mask_rect.xy) / mask_rect.zw;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return false;
	}
	return textureLod(blocker_mask, uv, 0.0).r > 0.5;
}

const float BAYER[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

float hash(vec2 p) {
	p = fract(p * vec2(0.1031, 0.1030));
	p += dot(p, p.yx + 33.33);
	return fract((p.x + p.y) * p.x);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amp = 0.55;
	for (int i = 0; i < 3; i++) {
		total += value_noise(p) * amp;
		p = p * 2.03 + vec2(17.1, 9.2);
		amp *= 0.45;
	}
	return total / 0.8;
}

float bayer4(vec2 q) {
	ivec2 i = ivec2(mod(q, 4.0));
	return (BAYER[i.x + i.y * 4] + 0.5) / 16.0;
}

int tuft_pixel(vec2 lp, float sway) {
	float y = lp.y;
	float t = clamp(-y / 6.0, 0.0, 1.0);
	float x = lp.x - floor(sway * t * t + 0.5);
	if ((x == 0.0 && y == -6.0) || (x == -3.0 && y == -4.0) || (x == 3.0 && y == -5.0)) {
		return 3;
	}
	bool blade = (x == 0.0 && y <= 0.0 && y >= -5.0)
		|| (x == -1.0 && (y == 0.0 || y == -1.0))
		|| (x == -2.0 && (y == -2.0 || y == -3.0))
		|| (x == 1.0 && (y == 0.0 || y == -1.0))
		|| (x == 2.0 && (y == -2.0 || y == -3.0))
		|| (x == 3.0 && y == -4.0);
	if (blade) {
		return y >= -1.0 ? 1 : 2;
	}
	return 0;
}

vec3 flower_pixel(vec2 lp, vec3 petal, vec3 under) {
	float ax = abs(lp.x);
	float ay = abs(lp.y);
	if (ax == 0.0 && ay == 0.0) {
		return flower_centre.rgb;
	}
	if (ax + ay == 1.0) {
		return petal;
	}
	if (ax == 1.0 && ay == 1.0) {
		return mix(petal, under, 0.45);
	}
	if (lp.y == 2.0 && lp.x >= -1.0 && lp.x <= 0.0) {
		return color_deep.rgb;
	}
	return under;
}

vec3 grass_color(vec2 q, vec2 wp) {
	vec3 col;
	if (original_grass) {
		col = texture(overlay_tex, wp * overlay_scale).rgb;
	} else {
		float v = fbm(q / patch_scale);
		float band = mod(floor((q.x + q.y * 0.35) / stripe_width), 2.0) * 2.0 - 1.0;
		v += band * stripe_strength * 0.5;
		v += (bayer4(q) - 0.5) * dither_strength;

		col = color_dark.rgb;
		if (v > 0.38) {
			col = color_mid.rgb;
		}
		if (v > 0.6) {
			col = color_light.rgb;
		}

		float h = hash(q + 71.3);
		if (h > 1.0 - speckle_amount) {
			col = v > 0.5 ? color_tip.rgb : color_light.rgb;
		} else if (h < speckle_amount * 0.6) {
			col = v > 0.5 ? color_dark.rgb : color_deep.rgb;
		}
	}

	vec2 cell = floor(q / tuft_cell);
	vec2 origin = vec2(
		6.0 + floor(hash(cell + 13.1) * (tuft_cell - 12.0)),
		8.0 + floor(hash(cell + 7.3) * (tuft_cell - 10.0)));
	if (show_tufts && hash(cell + 5.7) < tuft_density && !is_blocked((cell * tuft_cell + origin + 0.5) * pixel_size)) {
		vec2 lp = q - cell * tuft_cell - origin;
		if (hash(cell + 2.2) < 0.5) {
			lp.x = -lp.x;
		}
		float sway = sin(TIME * wind_speed + cell.x * 0.7 + cell.y * 0.3) * wind_pixels;
		int t = tuft_pixel(lp, sway);
		if (t == 1) {
			col = color_deep.rgb;
		} else if (t == 2) {
			col = color_light.rgb;
		} else if (t == 3) {
			col = color_tip.rgb;
		} else if (lp.y == 1.0 && abs(lp.x) <= 2.0) {
			col = mix(col, color_deep.rgb, 0.55);
		} else if (tuft_pixel(lp + vec2(1.0, 0.0), sway) > 0 || tuft_pixel(lp - vec2(1.0, 0.0), sway) > 0
				|| tuft_pixel(lp + vec2(0.0, 1.0), sway) > 0 || tuft_pixel(lp - vec2(0.0, 1.0), sway) > 0) {
			col = tuft_outline.rgb;
		}
	}

	vec2 fcell = floor(q / flower_cell);
	if (hash(fcell + 3.7) < flower_density) {
		vec2 centre = vec2(
			6.0 + floor(hash(fcell + 1.9) * (flower_cell - 12.0)),
			3.0 + floor(hash(fcell + 8.4) * (flower_cell - 9.0)));
		float kind = hash(fcell + 22.2);
		vec3 petal = kind < 0.45 ? flower_white.rgb : (kind < 0.75 ? flower_yellow.rgb : flower_pink.rgb);
		if (!is_blocked((fcell * flower_cell + centre + 0.5) * pixel_size)) {
			col = flower_pixel(q - fcell * flower_cell - centre, petal, col);
		}
		vec2 buddy = centre + vec2(hash(fcell + 5.5) < 0.5 ? -4.0 : 4.0, 3.0);
		if (hash(fcell + 41.0) < 0.55 && !is_blocked((fcell * flower_cell + buddy + 0.5) * pixel_size)) {
			col = flower_pixel(q - fcell * flower_cell - buddy, petal, col);
		}
	}

	return col;
}

float infection_at(vec2 wp, float fallback) {
	if (!use_infection_mask) {
		return fallback;
	}
	vec2 uv = (wp - infection_rect.xy) / infection_rect.zw;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return 0.0;
	}
	return textureLod(infection_mask, uv, 0.0).r;
}

vec3 add_seeps(vec2 q, vec3 col) {
	vec2 vc = floor(q / vent_cell);
	if (hash(vc + 9.1) >= vent_density) {
		return col;
	}
	vec2 centre = vc * vent_cell + vec2(
		5.0 + floor(hash(vc + 1.7) * (vent_cell - 10.0)),
		6.0 + floor(hash(vc + 2.9) * (vent_cell - 10.0)));
	if (infection_at((centre + 0.5) * pixel_size, 1.0) < 0.97) {
		return col;
	}
	vec2 lp = q - centre;
	float period = 4.0 + hash(vc + 4.4) * 4.0;
	float ph = fract(TIME / period + hash(vc + 6.6));
	if (lp == vec2(0.0)) {
		col = inf_pore.rgb;
	}
	if (ph < 0.35) {
		float r = 0.4 + 1.2 * ph / 0.35;
		vec2 bc = vec2(0.0, -r * 0.6);
		if (r > 1.0 && lp == floor(bc + vec2(-0.6, -0.6) + 0.5)) {
			col = inf_goo_light.rgb;
		} else if (length(lp - bc) <= r) {
			col = inf_goo.rgb;
		}
	} else if (ph < 0.4) {
		vec2 d = lp - vec2(0.0, -1.0);
		float ring = 1.5 + (ph - 0.35) / 0.05 * 1.2;
		float bucket = floor((atan(d.y, d.x) + 3.1416) / 0.8);
		if (abs(length(d) - ring) < 0.5 && hash(vc + bucket * 1.7) > 0.5) {
			col = inf_goo_light.rgb;
		}
	} else if (ph < 0.75) {
		float tt = (ph - 0.4) / 0.35 * 0.8;
		for (int k = 0; k < 3; k++) {
			float fk = float(k);
			float vx = (hash(vc + fk * 1.3 + 0.7) - 0.5) * 6.0;
			float vy = -(6.0 + hash(vc + fk * 2.1 + 0.2) * 4.0);
			float g = 30.0;
			float land = -2.0 * vy / g;
			if (tt < land) {
				vec2 pos = vec2(vx * tt, -1.0 + vy * tt + 0.5 * g * tt * tt);
				if (length(lp - pos) < 0.6) {
					col = inf_goo.rgb;
				}
			} else if (tt < land + 0.2 && lp == vec2(floor(vx * land + 0.5), -1.0)) {
				col = mix(col, inf_goo.rgb, 0.6);
			}
		}
	}
	return col;
}

vec3 infection_color(vec2 q, vec3 tex, float inf) {
	vec3 col = tex;
	if (tex.r < 0.3) {
		float front = clamp((1.0 - inf) * 2.0, 0.0, 1.0);
		float active = step(1.0 - crack_coverage, value_noise(q / 14.0 + 77.0));
		float flow = sin(TIME * pulse_speed - value_noise(q / 30.0) * 12.0);
		float surge = sin(inf * 14.0 + TIME * 1.6) * front;
		if ((flow > 0.78 && active > 0.5) || surge > 0.6) {
			col = mix(col, inf_glow.rgb, crack_glow);
		} else if ((flow > 0.6 && active > 0.5) || surge > 0.45) {
			col = mix(col, inf_glow.rgb, crack_glow * 0.45);
		}
	}
	float spore = hash(q + 5.1);
	if (spore > 0.997 && sin(TIME * 2.0 + spore * 400.0) > 0.7) {
		col = mix(col, inf_goo_light.rgb, 0.7);
	}
	return add_seeps(q, col);
}

vec3 infection_stain(vec2 q, vec3 col, float inf) {
	if (inf <= 0.02) {
		return col;
	}
	float n = value_noise(q / 5.0);
	float creep = 0.06 * sin(TIME * creep_speed + n * 5.0);
	float threshold = creep_reach - creep + (n - 0.5) * 0.25 + (bayer4(q) - 0.5) * 0.03;
	vec2 tq = q + (vec2(value_noise(q / 6.0 + 40.0), value_noise(q / 6.0 + 90.0)) - 0.5) * 6.0;
	float tendril = abs(value_noise(tq / 4.0 + 11.0) - 0.5);
	float width = inf > threshold ? 0.05 : 0.03;
	if (tendril < width && inf > threshold - 0.1) {
		return mix(col, inf_stain_dark.rgb, 0.8);
	}
	if (inf > threshold) {
		return mix(col, inf_stain.rgb, stain_strength * 0.4);
	}
	return col;
}

void vertex() {
	worldPosition = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 q = floor(worldPosition / pixel_size);
	float inf = infection_enabled ? infection_at((q + 0.5) * pixel_size, 0.0) : 0.0;
	if (floor(COLOR.r) > 0.5) {
		vec3 col = grass_color(q, worldPosition);
		if (infection_enabled) {
			col = infection_stain(q, col, inf);
		}
		COLOR = vec4(col, 1.0);
	} else if (infection_enabled && COLOR.a > 0.5 && COLOR.b > COLOR.g) {
		COLOR = vec4(infection_color(q, COLOR.rgb, use_infection_mask ? inf : 1.0), COLOR.a);
	}
}
