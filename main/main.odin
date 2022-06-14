package main

import "core:log"
import "vendor:raylib"
// import "core:fmt"
import "core:time"
// import "core:math"
import "core:math/rand"
import "core:math/linalg"


total_rocks :: 1000
screen_width :: 2560
screen_height :: 1440
target_fps :: 60
default: raylib.Shader
rock: raylib.Model
camera: raylib.Camera
rock_color := raylib.Color{80, 80, 80, 255}
rock_position := raylib.Vector3{0.0, 0.0, 0.0}
center := raylib.Vector3{0.0, 0.0, 0.0}
rock_texture: raylib.Texture2D
rock_normal: raylib.Texture2D
target: raylib.Vector3
dist: f32
ntarget: raylib.Vector3
position: raylib.Vector3
acceleration :f32: 0.01
turn_acceleration :f32: 0.0001
speed : f32 = 0
up_down_speed : f32 = 0
left_right_speed : f32 = 0
up := raylib.Vector3{0.0, 1.0, 0.0}
max_speed :: 2.0
max_turn_speed :: 0.1

Rock_State :: struct {
	id: int,
	scale: f32,
	position: raylib.Vector3,
	rotation_axis: raylib.Vector3,
	rotation: f32,
	rotation_delta: f32,
}

rocks := [total_rocks]Rock_State{}

random_vec :: proc(rng: ^rand.Rand, lo, hi: f32) -> raylib.Vector3 {
	return raylib.Vector3 {
		rand.float32_range(lo, hi, rng),
		rand.float32_range(lo, hi, rng),
		rand.float32_range(lo, hi, rng),
	}
}

build_rocks :: proc(rng: ^rand.Rand, blo, bhi: f32) {
	for i := 0; i < total_rocks; i += 1 {
		r := &rocks[i]
		r.id = i
		r.scale = rand.float32_range(0.1, 0.8, rng)
		r.position = random_vec(rng, blo, bhi)
		r.rotation_axis = random_vec(rng, 0, 1.0)
		r.rotation = rand.float32_range(0, 360, rng)
		r.rotation_delta = rand.float32_range(-0.4, 0.4, rng)
	}
}

draw_rock :: proc(idx: int) {
	r := &rocks[idx]
	raylib.rlPushMatrix()
		raylib.rlTranslatef(r.position.x, r.position.y, r.position.z)
		raylib.rlPushMatrix()
			raylib.rlRotatef(r.rotation, r.rotation_axis.x, r.rotation_axis.y, r.rotation_axis.z)
			raylib.DrawModel(rock, raylib.Vector3{0,0,0}, r.scale, raylib.WHITE)
		raylib.rlPopMatrix()
	raylib.rlPopMatrix()
}

update_rock :: proc(idx: int) {
	r := &rocks[idx]
	r.rotation += r.rotation_delta
	if r.rotation >= 360 {
		r.rotation -= 360
	}
}

update_camera :: proc() {
	if raylib.IsKeyDown(raylib.KeyboardKey.SPACE) {
		speed += acceleration
		if speed > max_speed {
			speed = max_speed
		}
	} else {
		speed -= acceleration
		if speed < 0 {
			speed = 0
		}
	}

	w := raylib.IsKeyDown(raylib.KeyboardKey.W)
	s := raylib.IsKeyDown(raylib.KeyboardKey.S)
	a := raylib.IsKeyDown(raylib.KeyboardKey.A)
	d := raylib.IsKeyDown(raylib.KeyboardKey.D)

	switch {
		case w && s:
			up_down_speed = 0
		case w:
			up_down_speed += turn_acceleration
			if up_down_speed > max_turn_speed {
				up_down_speed = max_turn_speed
			}
		case s:
			up_down_speed -= turn_acceleration
			if up_down_speed < -max_turn_speed {
				up_down_speed = -max_turn_speed
			}
		case:
			if up_down_speed > 0 {
				up_down_speed -= turn_acceleration
				if up_down_speed < 0 {
					up_down_speed = 0
				}
			} else if up_down_speed < 0 {
				up_down_speed += turn_acceleration
				if up_down_speed > 0 {
					up_down_speed = 0
				}
			}
	}

	switch {
		case a && d:
			left_right_speed = 0
		case d:
			left_right_speed += turn_acceleration
			if left_right_speed > max_turn_speed {
				left_right_speed = max_turn_speed
			}
		case a:
			left_right_speed -= turn_acceleration
			if left_right_speed < -max_turn_speed {
				left_right_speed = -max_turn_speed
			}
		case:
			if left_right_speed > 0 {
				left_right_speed -= turn_acceleration
				if left_right_speed < 0 {
					left_right_speed = 0
				}
			} else if left_right_speed < 0 {
				left_right_speed += turn_acceleration
				if left_right_speed > 0 {
					left_right_speed = 0
				}
			}
	}

	xrot := linalg.matrix4_from_yaw_pitch_roll(left_right_speed, up_down_speed, 0)
	ntv4 := raylib.Vector4{ntarget.x, ntarget.y, ntarget.z, 0}
	upv4 := raylib.Vector4{up.x, up.y, up.z, 0}
	ntv4 = ntv4 * xrot
	upv4 = upv4 * xrot
	ntarget = ntv4.xyz
	position += ntarget * speed
	up = upv4.xyz
}

main :: proc() {
	context.logger = log.create_console_logger()
	rng : rand.Rand
	rand.init(&rng, auto_cast time.time_to_unix(time.now()))
	raylib.InitWindow(screen_width, screen_height, "-- Game: The Game --")
	raylib.SetTargetFPS(target_fps)
	rock = raylib.LoadModel("resources/models/source/rock.obj")
	rock_texture = raylib.LoadTexture("resources/models/textures/rock-tex.png")
	rock_normal = raylib.LoadTexture("resources/models/textures/rock-nor.png")
	bb := raylib.GetModelBoundingBox(rock)
	position = raylib.Vector3{target.x, target.y, bb.min.z - 600.0}
	ntarget = linalg.vector_normalize(target - position)
	dist = linalg.length(target - position)

	log.infof("ntarget: %v", ntarget)

	default = raylib.LoadShader(
		"resources/shaders/default.vs",
		"resources/shaders/default.fs",
	)
	camera = raylib.Camera{
		position,
		position + (ntarget*dist),
		up,
		45.0,
		raylib.CameraProjection.PERSPECTIVE,
	}
	rock.materials[0].shader = default
	rock.materials[0].maps[raylib.MaterialMapIndex.ALBEDO].texture = rock_texture
	rock.materials[0].maps[raylib.MaterialMapIndex.NORMAL].texture = rock_normal

	build_rocks(&rng, -800, 800)

	lightPos := raylib.GetShaderLocation(default, "lightPos")
	light_pos := []f32{camera.position[0], camera.position[1], camera.position[2]}
	raylib.SetShaderValue(
		default,
		raylib.ShaderLocationIndex(lightPos),
		raw_data(light_pos),
		raylib.ShaderUniformDataType.VEC3,
	)

	p : f32 = 0.0
	itime := f32(raylib.GetTime())

	for !raylib.WindowShouldClose() {
		if raylib.IsKeyPressed(raylib.KeyboardKey.Q) do break

		raylib.BeginDrawing()
			update_camera()
			camera.position = position
			camera.target = position + (ntarget*dist)
			camera.up = up
			raylib.ClearBackground(raylib.BLACK)
			raylib.BeginMode3D(camera) // Begin 3d mode drawing
			for i := 0; i < total_rocks; i += 1 {
				draw_rock(i)
				update_rock(i)
			}
			raylib.DrawSphere(camera.target, 5, raylib.RED)
			raylib.DrawSphere(center, 5, raylib.GREEN)
			raylib.DrawRay(raylib.Ray{
				direction = camera.up,
				position = camera.target,
				}, raylib.YELLOW)

			delta := int(f32(raylib.GetTime())-itime)
			p = f32(delta%10 + 1)/10.0
			v := linalg.lerp(camera.position, camera.target, raylib.Vector3{p,p,p})
			raylib.DrawSphere(v, 2, raylib.BLUE)
			raylib.EndMode3D() // End 3d mode drawing, returns to orthographic 2d mode
		raylib.EndDrawing()
	}

	raylib.UnloadShader(default)
	raylib.UnloadTexture(rock_normal)
	raylib.UnloadTexture(rock_texture)
	raylib.UnloadModel(rock)
	raylib.CloseWindow()
}
