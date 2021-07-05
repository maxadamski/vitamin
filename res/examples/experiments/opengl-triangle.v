use import tensor, glfw, gl

vertices : Tensor = [
	-0.6 -0.4 1 0 0,
	0.6 -0.4 0 1 0,
	0.0  0.6 0 0 1,
]

vertex-shader-text = """
#version 110
uniform mat4 MVP;
attribute vec3 vCol;
attribute vec2 vPos;
varying vec3 color;
void main() {
	gl_Position = MVP * vec4(vPos, 0.0, 1.0);
}
"""

fragment-shader-text = """
#version 110
varying vec3 color;
void main() {
	gl_FragColor = vec4(color, 1.0);
}
"""

on-error(code: I32, text: String) =
	print(stderr, "error: \(text)")
 
on-key(window: &Window, key code action mods: I32) =
	if key == .escape and action == .press
		set-window-should-close(window, true)

main() =
	error-callback(on-error)
	if not glfw.init() return
	defer glfw.terminate()
	window-hint(.version-major, 2)
	window-hint(.version-minor, 0)
	window = create-window(640, 480, title="OpenGL Example")
	if not window return
	defer destroy-widnow(window)
	key-callback(window, on-key)
	current-context(window)
	swap-interval(1)

	vertex-buffer = make-buffer(.array-buffer, vertices, .static-draw)
    vertex-shader = make-shader(vertex-shader-text, .vertex-shader)
    fragment-shader = make-shader(fragment-shader-text, .fragment-shader)
	program = create-program()
	attach(program, vertex-shader, fragment-shader)
	link(program)

	mvp-loc = uniform-location(program, 'MVP')
	vpos-loc, vcol-loc = attribute-locations(program, 'vPos', 'vCol')
	vertex-attribute(vpos-loc, 2, Float)
	vertex-attribute(vcol-loc, 3, Float)

	while not window-closed(window)
		width, height = framebuffer-size(window)
		ratio = width / height
		viewport(0, 0, width, height)
		clear(.color-buffer-bit)

		m = identity(4)
		m = rotate-z(m, to-float(get-time()))
		p = orth(-ratio, ratio, -1, 1, 1, -1)
		mvp = p * m

		use-program(program)
		set-uniform-matrix(mvp-loc, mvp)
		draw-arrays(.triangles, 0, 3)
		swap-buffers(window)
		poll-events()

