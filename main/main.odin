package main

import "core:log"
import "vendor:raylib"
// import "core:fmt"
import "core:math"
// import "core:math/linalg"

screen_width :: 1920
screen_height :: 1080
target_fps :: 60
default: raylib.Shader
rock: raylib.Model
camera: raylib.Camera
rock_color := raylib.Color{80, 80, 80, 255}
rock_position := raylib.Vector3{0.0, 0.0, 0.0}
rock_texture: raylib.Texture2D
rock_normal: raylib.Texture2D

rrotate :: proc(val: int, limit: int) -> f32 {
	return f32(math.lerp(0.0, 360.0, f64(val)/f64(limit)))
}

main :: proc() {
	context.logger = log.create_console_logger()
	raylib.InitWindow(screen_width, screen_height, "-- Game: The Game --")
	raylib.SetTargetFPS(target_fps)
	rock = raylib.LoadModel("resources/models/source/rock.obj")
	rock_texture = raylib.LoadTexture("resources/models/textures/rock-tex.png")
	rock_normal = raylib.LoadTexture("resources/models/textures/rock-nor.png")
	bb := raylib.GetModelBoundingBox(rock)
	mp := (bb.min + bb.max) / 2.0
	default = raylib.LoadShader(
		"resources/shaders/default.vs",
		"resources/shaders/default.fs",
	)
	camera = raylib.Camera{
		{mp.x, mp.y, bb.min.z - 60.0},
		mp,
		{0.0, 1.0, 0.0},
		45.0,
		raylib.CameraProjection.PERSPECTIVE,
	}
	rock.materials[0].shader = default
	rock.materials[0].maps[raylib.MaterialMapIndex.ALBEDO].texture = rock_texture
	rock.materials[0].maps[raylib.MaterialMapIndex.NORMAL].texture = rock_normal

	// mvp := raylib.GetShaderLocation(default, "mvp")
	lightPos := raylib.GetShaderLocation(default, "lightPos")
	light_pos := []f32{camera.position[0], camera.position[1], camera.position[2]}
	raylib.SetShaderValue(
		default,
		raylib.ShaderLocationIndex(lightPos),
		raw_data(light_pos),
		raylib.ShaderUniformDataType.VEC3,
	)

	w := raylib.GetScreenWidth()
	h := raylib.GetScreenHeight()

	for !raylib.WindowShouldClose() {
		if raylib.IsKeyPressed(raylib.KeyboardKey.Q) do break
		x := raylib.GetMouseX()
		y := raylib.GetMouseY()
		rx := rrotate(auto_cast x, auto_cast w)
		ry := rrotate(auto_cast y, auto_cast h)

		raylib.BeginDrawing()
			raylib.ClearBackground(raylib.BLACK)
			raylib.BeginMode3D(camera) // Begin 3d mode drawing
			raylib.rlPushMatrix()
				raylib.rlRotatef(rx, 0.0, 1.0, 0)
				raylib.rlRotatef(ry, 1.0, 0.0, 0)
				raylib.DrawModel(rock, rock_position, 1.0, raylib.WHITE)
			raylib.rlPopMatrix()
			raylib.EndMode3D() // End 3d mode drawing, returns to orthographic 2d mode
		raylib.EndDrawing()
	}

	raylib.UnloadShader(default)
	raylib.UnloadTexture(rock_normal)
	raylib.UnloadTexture(rock_texture)
	raylib.UnloadModel(rock)
	raylib.CloseWindow()
}
