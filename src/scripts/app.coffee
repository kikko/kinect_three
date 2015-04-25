Skeleton = require './body'
# Playback = require './playback'

fx = {}
fx.TestEffectDress   = require './effects/effect_dress'
fx.TestEffectLines   = require './effects/effect_lines'
fx.TestEffectPhysics = require './effects/effect_physics'
fx.BodyExtrusion     = require './effects/effect_body_extrusion'

class App

	constructor : ->
		@setupThreejs()
		@setupSkeleton()
		@setupUI()
		@setupDefaults()
		@bDrawDebugView = false
		window.addEventListener 'focus', (=> @start()), false
		window.addEventListener 'blur', (=> @stop()), false
		window.addEventListener 'resize', (=> @windowResized()), false
		window.addEventListener 'keydown', @onKeyDown, false

	setupThreejs : ->
		@scene = new THREE.Scene()
		@camera = new THREE.PerspectiveCamera 60, window.innerWidth / window.innerHeight, 0.001, 500
		@camera.position.z = -2
		
		if window.WebGLRenderingContext
			@renderer = new THREE.WebGLRenderer antialias:true
		else
			@renderer = new THREE.CanvasRenderer()
		# @renderer.setClearColor 0x444444, 1
		@renderer.setClearColor 0xffffff, 1
		@renderer.setSize window.innerWidth, window.innerHeight
		@renderer.autoClear = false
		# @renderer.gammaInput = true;
		# @renderer.gammaOutput = true
		# @renderer.shadowMapEnabled = true
		document.body.appendChild @renderer.domElement

		window.setDarkTheme = =>
			@renderer.setClearColor 0x222222, 1


		@controls = new THREE.OrbitControls @camera, @renderer.domElement

		@grid = new THREE.GridHelper 3, 0.25
		@grid.position.y -= 0.8
		@scene.add @grid

	setupSkeleton : ->

		@tracker = new ks.Tracker
		@tracker.addListener 'user_in',  @onKinectUserIn
		@tracker.addListener 'user_out', @onKinectUserOut

		@kinectProxy = new ks.Playback @tracker

		@ksview = new ks.DebugView @tracker
		@ksview.proxy = @kinectProxy
		@ksview.canvas.style.position = 'absolute'
		@ksview.canvas.style.right = '0'
		@ksview.canvas.style.bottom = '-30px'

		@skeleton = new Skeleton()

	setupUI : ->
		$('#debug').change (ev) =>
			debug = ev.target.checked
			@setDebugMode debug
		$('#file').change (ev) =>
			fileName = $('#file').find('option:selected').val()
			@setPlaybackFile fileName
		$('#effect').change (ev) =>
			effectName = $('#effect').find('option:selected').val()
			@setEffect effectName

	setupDefaults : ->
		effectName = $('#effect').find('option:selected').val()
		@setEffect effectName
		debug = $('#debug').attr('checked')
		@setDebugMode debug
		fileName = $('#file').find('option:selected').val()
		@setPlaybackFile fileName

	start : ->
		@animate() if !@animFrameId

	stop : ->
		if @animFrameId
			window.cancelAnimationFrame @animFrameId
			@animFrameId = null

	animate : =>
		@animFrameId = requestAnimationFrame @animate
		@update 1000 / 60
		@controls.update()
		@render()

	update : (dt) ->
		delta = 1000 / 60
		@ksview.render() if @bDrawDebugView
		@skeleton.update()
		@effect.update dt if @effect

	render : ->
		@renderer.clear()
		@renderer.render @scene, @camera
		if @debug
			# @renderer.clearDepth()
			@renderer.render @skeleton.scene, @camera

# Kinect Events

	onKinectUserIn : (ev) =>
		return if @tracker.bodies.length != 1
		@skeleton.setBody ev.body
		if @effect
			@setEffect @effect.constructor.name

	onKinectUserOut : (ev) =>
		#destroy current skeleton


# Controls

	setDebugMode : (@debug=false) ->
		@grid.visible = @debug
		@skeleton.view.visible = @debug
		@effect.setDebugMode @debug if @effect

	setEffect : (effectName) ->
		if @effect
			@effect.stop()
			@scene.remove @effect.view
		EffectClass = fx[effectName]
		if EffectClass
			@effect = new EffectClass @skeleton, @scene
			@scene.add @effect.view

	setPlaybackFile : (fileName) ->
			# @kinectProxy.framerate = 15
			@kinectProxy.play 'assets/kinect/' + fileName + '.json.gz'
		# @kinectProxy.connect "ws://192.168.0.40:9092"

# System Events

	windowResized : (ev) ->
		@camera.aspect = window.innerWidth / window.innerHeight
		@camera.updateProjectionMatrix()
		@renderer.setSize window.innerWidth, window.innerHeight
		@render()

	onKeyDown : (event) =>
		if event.keyCode == 9
			event.preventDefault()
			@bDrawDebugView = !@bDrawDebugView
			if @bDrawDebugView
				document.body.appendChild @ksview.canvas
			else
				document.body.removeChild @ksview.canvas

module.exports = App