
Namespace mojo.graphics

'------------------------------------------------------------
'jl added
const Pi180:double = Pi / 180
#rem monkeydoc Converts degrees in angles. E.G. 90 degrees to radians
Degrees start from 0 pointing East and then go counterclockwise.
So:
90 degrees is up (north)
180 degrees is pointing left (west)
280 degrees is pointing down (south)
See Also [[RadianToDegrees]]
#end
function DegreesToRadian:float( degrees:float )
	return degrees * Pi180' ) / 180.0
End function

#rem monkeydoc Converts radians to degrees in angles.
Degrees start from 0 pointing East and then go counterclockwise.
So:
90 degrees is up (north)
180 degrees is pointing left (west)
280 degrees is pointing down (south)
See Also [[DegreesToRadian]]
#end
function RadianToDegrees:float( radian:float )
	return radian / Pi180
End function


#rem monkeydoc Liniear Interp
#end
function Lerp:Double( a:double, b:double, t:double )
	return (1.0-t) * a + t*b
End function

#rem monkeydoc Linear Interp
#end
function Slerp:Double( a:double, b:double, t:double )
	return (1.0-t) * a + t*b
End function

#rem monkeydoc Converts 4 byts or ints to a packed integer color
Get an integer packed color from rgba inputs (0..255)
#end
function ICol:Uint( r:int, g:int, b:int, a:int = 255 )
	r = Clamp(r, 0, 255)
	g = Clamp(g, 0, 255)
	b = Clamp(b, 0, 255)
	a = Clamp(a, 0, 255)
	Return UInt(a) Shl 24 | UInt(b) Shl 16 | UInt(g) Shl 8 | UInt(r)
End function

'------------------------------------------------------------


#rem monkeydoc Outline modes.

Outline modes are used with the [[Canvas.OutlineMode]] property and control the style
of outline drawn.

| OutlineMode	| Description
|:--------------|:-----------
| None			| Outlines disabled.
| Solid			| Solid outlines.
| Smooth		| Smooth outlines.

#end
Enum OutlineMode
	None=0
	Solid=1
	Smooth=2
End

#rem monkeydoc The Canvas class.

Canvas objects are used to perform rendering to either a mojo [[View]] or an 'off screen' [[Image]].

To draw to a canvas, use one of the 'Draw' methods. Drawing is affected by a number of draw states, including:

* [[Color]] - the current drawing color. This is combined with the current alpha to produce the final rendering color and alpha values.
* [[Alpha]] - the current drawing alpha level.
* [[Matrix]] - the current drawing matrix. All drawing coordinates are multiplied by this matrix before rendering.
* [[BlendMode]] - the blending mode for drawing, eg: opaque, alpha, additive, multiply.
* [[Viewport]] - the current viewport. All drawing coordinates are relative to the top-left of the viewport.
* [[Scissor]] - the current scissor rect. All rendering is clipped to the union of the viewport and the scissor rect.
* [[Font]] - The current font to use when drawing text with [[DrawText]].

Drawing does not occur immediately. Drawing commands are 'buffered' to reduce the overhead of sending lots of draw calls to the lower level graphics API. You can force all drawing commands in the buffer to actually render using [[Flush]].

#end
Class Canvas

'------------------------------------------------------------
	'start of jl jeanluc additions
	Field RenderAmbient:void( device:GraphicsDevice )
	
	method SetCol( color:UInt )
		_pmcolor = color
	End method

	method SetCol( r:int, g:int, b:int, a:int = 255 )
		r = Clamp(r, 0, 255)
		g = Clamp(g, 0, 255)
		b = Clamp(b, 0, 255)
		a = Clamp(a, 0, 255)
		_pmcolor = UInt(a) Shl 24 | UInt(b) Shl 16 | UInt(g) Shl 8 | UInt(r)
	End method


	method SetViewport( x:float, y:float, w:float, h:float )
		If _lighting return

		Flush()
			
		_viewport = New Rectf( x,y,x+w,y+h )
		
		_dirty |= Dirty.Viewport | Dirty.Scissor
	End method
	
	
	Method DrawTextVSize( text:String, tx:Float, ty:Float, xSize:float = 1, ySize:float = 1 )
		If Not text.Length Return
	
'		tx-=_font.TextWidth( text ) * handleX
'		ty-=_font.Height * handleY
		
		Local gpage:=_font.GetGlyphPage( text[0] )
		If Not gpage gpage=_font.GetGlyphPage( 0 )

		Local sx:Float
		Local sy:Float
		Local tw:Float
		Local th:Float
		
		Local i0:=0
		
		while i0 < text.Length
			Local i1:=i0+1
			Local page:Image'GlyphPage
			
			While i1<text.Length
				page=_font.GetGlyphPage( text[i1] )
				If page And page<>gpage Exit
				
				i1+=1
			Wend

			Local image:Image = gpage
			sx = image.Rect.min.x
			sy = image.Rect.min.y
			tw = image.Texture.Width
			th = image.Texture.Height
			AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
			
			For Local i:=i0 Until i1
				Local g:=_font.GetGlyph( text[i] )
			
				Local s0:float = Float( g.rect.min.x + sx ) / tw
				Local t0:float = Float( g.rect.min.y + sy ) / th
				Local s1:float = Float( g.rect.max.x + sx ) / tw
				Local t1:float = Float( g.rect.max.y + sy ) / th
				
				Local x0:float = Round( tx + g.offset.y )
				Local y0:float = Round( ty + g.offset.x )
				Local x1:float = x0 + g.rect.Height * ySize
				Local y1:float = y0 + g.rect.Width * xSize
	
				AddVertex( x0,y0, s0,t1 )
				AddVertex( x1,y0, s0,t0 )
				AddVertex( x1,y1, s1,t0 )
				AddVertex( x0,y1, s1,t1 )
				
				ty += g.rect.Width * xSize
			Next
			
			gpage=page
			
			i0=i1
		Wend
	End


	Method DrawTextSize( text:String, tx:Float, ty:Float, xSize:float = 1, ySize:float = 1 )
		If Not text.Length Return
	
'		tx-=_font.TextWidth( text ) * handleX
'		ty-=_font.Height * handleY
		
		Local gpage:=_font.GetGlyphPage( text[0] )
		If Not gpage gpage=_font.GetGlyphPage( 0 )

		Local sx:Float
		local sy:Float
		Local tw:Float
		Local th:Float
		
		Local i0:=0
		
		while i0 < text.Length
			Local i1:=i0+1
			Local page:Image'GlyphPage
			
			While i1<text.Length
				page=_font.GetGlyphPage( text[i1] )
				If page And page<>gpage Exit
				
				i1+=1
			Wend

			Local image:=gpage
			sx = image.Rect.min.x
			sy = image.Rect.min.y
			tw = image.Texture.Width
			th = image.Texture.Height
			AddDrawOp( image.Shader, image.Material, image.BlendMode, 4, i1-i0 )
			
			For Local i:=i0 Until i1
				Local g:=_font.GetGlyph( text[i] )
			
				Local s0:float = Float( g.rect.min.x + sx ) / tw
				Local t0:float = Float( g.rect.min.y + sy ) / th
				Local s1:float = Float( g.rect.max.x + sx ) / tw
				Local t1:float = Float( g.rect.max.y + sy ) / th
				
				Local x0 := Round( tx+g.offset.x )
				Local y0 := Round( ty+g.offset.y )
				Local x1 := x0 + g.rect.Width * xSize
				Local y1 := y0 + g.rect.Height * ySize
	
				AddVertex( x0, y0, s0, t0 )
				AddVertex( x1, y0, s1, t0 )
				AddVertex( x1, y1, s1, t1 )
				AddVertex( x0, y1, s0, t1 )
				
				tx += g.advance * xSize
			Next
			
			gpage=page
			
			i0=i1
		Wend
	End method


	Method DrawTextBold( text:String, tx:Float, ty:Float )
		If Not text.Length Return

		DrawText( text, tx, ty )
		DrawText( text, tx+1, ty )
	End method


	Method DrawTextBold( text:String, tx:Float, ty:Float, bold:float, handleX:Float=0,handleY:Float=0 )
		If Not text.Length Return
		
		bold /= 10
		Local bold2:float = bold + bold
	
		tx-=_font.TextWidth( text ) * handleX
		ty-=_font.Height * handleY
		
		Local gpage:=_font.GetGlyphPage( text[0] )
		If Not gpage gpage=_font.GetGlyphPage( 0 )

		Local sx:Float
		local sy:Float
		Local tw:Float
		Local th:Float
		
		Local i0:=0
		
		while i0<text.Length
			Local i1:=i0+1
			Local page:Image'GlyphPage
			
			While i1<text.Length
				page=_font.GetGlyphPage( text[i1] )
				If page And page<>gpage Exit
				
				i1+=1
			Wend

			Local image:=gpage
			sx=image.Rect.min.x;sy=image.Rect.min.y
			tw=image.Texture.Width;th=image.Texture.Height
			AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
			
			For Local i:=i0 Until i1
				Local g:=_font.GetGlyph( text[i] )
			
				Local s0:=(Float(g.rect.min.x+sx)/tw)
				Local t0:=(Float(g.rect.min.y+sy)/th)
				Local s1:=(Float(g.rect.max.x+sx)/tw)
				Local t1:=(Float(g.rect.max.y+sy)/th)
				
				Local x0:=Round( tx+g.offset.x ) - bold
				Local y0:=Round( ty+g.offset.y ) - bold
				Local x1:=(x0+g.rect.Width) + bold2
				Local y1:=(y0+g.rect.Height) + bold2
	
				AddVertex( x0,y0,s0,t0 )
				AddVertex( x1,y0,s1,t0 )
				AddVertex( x1,y1,s1,t1 )
				AddVertex( x0,y1,s0,t1 )
				
				tx+=g.advance
			Next
			
			gpage=page
			
			i0=i1
		Wend

	End
	

	Method DrawTextV( text:String,tx:Float,ty:Float,handleX:Float=0,handleY:Float=0 )
		If Not text.Length Return
	
		tx-=_font.TextWidth( text ) * handleX
		ty-=_font.Height * handleY
		
		Local gpage:=_font.GetGlyphPage( text[0] )
		If Not gpage gpage=_font.GetGlyphPage( 0 )

		Local sx:Float
		Local sy:Float
		Local tw:Float
		Local th:Float
		
		Local i0:=0
		
		while i0 < text.Length
			Local i1:=i0+1
			Local page:Image'GlyphPage
			
			While i1<text.Length
				page=_font.GetGlyphPage( text[i1] )
				If page And page<>gpage Exit
				
				i1+=1
			Wend

			Local image:Image = gpage
			sx = image.Rect.min.x
			sy = image.Rect.min.y
			tw = image.Texture.Width
			th = image.Texture.Height
			AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
			
			For Local i:=i0 Until i1
				Local g:=_font.GetGlyph( text[i] )
			
				Local s0:float = Float( g.rect.min.x + sx ) / tw
				Local t0:float = Float( g.rect.min.y + sy ) / th
				Local s1:float = Float( g.rect.max.x + sx ) / tw
				Local t1:float = Float( g.rect.max.y + sy ) / th
				
'				Local x0:float = Round( tx + g.offset.y )
'				Local y0:float = Round( ty - g.offset.x )
'				Local x1:float = x0 + g.rect.Height
'				Local y1:float = y0 - g.rect.Width
'	
'				AddVertex( x0,y0, s0,t0 )
'				AddVertex( x1,y0, s0,t1 )
'				AddVertex( x1,y1, s1,t1 )
'				AddVertex( x0,y1, s1,t0 )
'				
'				ty -= g.rect.Width

				Local x0:float = Round( tx + g.offset.y )
				Local y0:float = Round( ty + g.offset.x )
				Local x1:float = x0 + g.rect.Height
				Local y1:float = y0 + g.rect.Width
	
				AddVertex( x0,y0, s0,t1 )
				AddVertex( x1,y0, s0,t0 )
				AddVertex( x1,y1, s1,t0 )
				AddVertex( x0,y1, s1,t1 )
				
				ty += g.rect.Width
			Next
			
			gpage=page
			
			i0=i1
		Wend
	End


	Method DrawTextSpacing( text:String, tx:Float, ty:Float, spacing:float, handleX:Float=0,handleY:Float=0 )
		If Not text.Length Return
		
		If spacing < 0.1 Then spacing = 0.1
	
		tx-=_font.TextWidth( text ) * handleX
		ty-=_font.Height * handleY
		
		Local gpage:=_font.GetGlyphPage( text[0] )
		If Not gpage gpage=_font.GetGlyphPage( 0 )

		Local sx:Float,sy:Float
		Local tw:Float,th:Float
		
		Local i0:=0
		
		while i0 < text.Length
			Local i1:=i0+1
			Local page:Image'GlyphPage
			
			While i1<text.Length
				page=_font.GetGlyphPage( text[i1] )
				If page And page<>gpage Exit
				
				i1+=1
			Wend

			Local image:=gpage
			sx=image.Rect.min.x;sy=image.Rect.min.y
			tw=image.Texture.Width;th=image.Texture.Height
			AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
			
			For Local i:=i0 Until i1
				Local g:=_font.GetGlyph( text[i] )
			
				Local s0:=Float(g.rect.min.x+sx)/tw
				Local t0:=Float(g.rect.min.y+sy)/th
				Local s1:=Float(g.rect.max.x+sx)/tw
				Local t1:=Float(g.rect.max.y+sy)/th
				
				Local x0:=Round( tx+g.offset.x )
				Local y0:=Round( ty+g.offset.y )
				Local x1:=x0+g.rect.Width
				Local y1:=y0+g.rect.Height
	
				AddVertex( x0,y0,s0,t0 )
				AddVertex( x1,y0,s1,t0 )
				AddVertex( x1,y1,s1,t1 )
				AddVertex( x0,y1,s0,t1 )
				
				tx += g.advance * spacing
			Next
			
			gpage=page
			
			i0=i1
		Wend

	End

	#rem monkeydoc Draws a grid of cells (made from lines).
	Draws a grid in the current [[Color]] using the current [[BlendMode]].
	The rectangle vertex coordinates are also transform by the current [[Matrix]].
	#end
	method DrawGrid( x:float, y:float, width:float, height:float, cell:float )
		width -= 1
		height -= 1
		Local k:float
		For k = x To x+width Step cell
			DrawLine( k, y, k, y+height )
		Next
		If height < 0 Then cell = -cell
		For k = y To y+height Step cell
			DrawLine( x, k, x+width, k )
		Next
		DrawLine( x, y+height, x+width, y+height )
		DrawLine( x+width, y, x+width, y+height )
	End method


	Method DrawFrameCircle( x:Float, y:Float, width:Float )
		DrawFrameOval( x, y, width, width )
	End method
	
	Method DrawFrameOval( x:Float, y:Float, width:Float, height:Float )
		Local xr := width'/2
		local yr := height'/2
		
		Local dx_x := xr*_matrix.i.x
		Local dx_y := xr*_matrix.i.y
		Local dy_x := yr*_matrix.j.x
		Local dy_y := yr*_matrix.j.y
		Local dx := Sqrt( dx_x*dx_x+dx_y*dx_y )
		Local dy := Sqrt( dy_x*dy_x+dy_y*dy_y )

		Local n := (Max( Int( dx+dy ),13 ) & ~3)
		
		Local x0 := x'+xr
		local y0 := y'+yr
		
		local th:float = .5*Pi*2/n
		local px:float
		local py:float
		local pxo:float = x0+Cos( th ) * xr
		local pyo:float = y0+Sin( th ) * yr
		
'		AddDrawOp( _shader, _material, _blendMode, n, 1 )
		
		For Local i:=1 to n
			th = (i+.5)*Pi*2/n
			px = x0+Cos( th ) * xr
			py = y0+Sin( th ) * yr
'			AddPointVertex( px,py,0,0 )
			DrawLine( px, py, pxo, pyo )
			pxo = px
			pyo = py
		Next
	End

	Method DrawFrameOval( x:Float, y:Float, width:Float, height:Float, fromAngle:float, toAngle:float )
		Local xr := width'/2
		local yr := height'/2
		
		Local dx_x := xr*_matrix.i.x
		Local dx_y := xr*_matrix.i.y
		Local dy_x := yr*_matrix.j.x
		Local dy_y := yr*_matrix.j.y
		Local dx := Sqrt( dx_x*dx_x+dx_y*dx_y )
		Local dy := Sqrt( dy_x*dy_x+dy_y*dy_y )

		Local n := (Max( Int( dx+dy ),13 ) & ~3)*0.2
		
		Local x0 := x'+xr
		local y0 := y'+yr
		
		local th:float = .5*Pi*2/n
		local px:float
		local py:float
		
'		AddDrawOp( _shader, _material, _blendMode, n, 1 )
		
		local div:float = (toAngle - fromAngle) / n
		th = fromAngle
		local pxo:float = x0+Cos( th ) * xr
		local pyo:float = y0+Sin( th ) * yr
		th += div
		For Local i:=1 to n
			px = x0+Cos( th ) * xr
			py = y0+Sin( th ) * yr
			DrawLine( px, py, pxo, pyo )
			pxo = px
			pyo = py
			th += div
		Next
	End

	Method DrawFrameOvalDepth( x:Float, y:Float, width:Float, height:Float, depth:float, scale:float )
		Local xr := width
		local yr := height
		
		Local dx_x := xr
		Local dx_y := xr
		Local dy_x := yr
		Local dy_y := yr
		Local dx := Sqrt( dx_x*dx_x+dx_y*dx_y )
		Local dy := Sqrt( dy_x*dy_x+dy_y*dy_y )

		Local n := (Max( Int( dx+dy ),13 ) & ~3) * 0.2
		
		Local x0 := x
		local y0 := y
		
		local th:float = .5*Pi*2/n
		local px:float
		local py:float
		
		local div:float = (Pi*2) / n
		th = -Pi*0.5
		local pxo:float = x0+Cos( th ) * xr
		local pyo:float = y0+Sin( th ) * yr
		th += div
		local offset:float
		local scaleDepth:float = scale * depth
		local cs:float
		'right side
		For Local i:=0 to n
			cs = Cos( th )
			offset = cs * scaleDepth
			px = x0 + cs * xr
			py = y0 + Sin( th ) * yr + offset
			DrawLine( px, py, pxo, pyo )
			pxo = px
			pyo = py
			th += div
		Next
	End


	method DrawRoundedRect( x:float, y:float, width:float, height:float, radius:float )
		Local n:float = radius * 0.75
		local pointX:float[] = New float[n]
		local pointY:float[] = New float[n]
		
		local x0:float = x + radius
		local y0:float = y + radius
		local px:float
		local py:float

		local div:float = (Pi*0.5) / n
		local theta:float = Pi
		n -= 1
		
		local k:int
		For k = 0 to n
			pointX[k] = Cos( theta ) * radius
			pointY[k] = Sin( theta ) * radius
			theta += div
		Next
		
		local x1:float = x + width
		local x1r:float = x1 - radius
		local y1:float = y + height
		local y1r:float = y1 - radius

		AddDrawOp( _shader, _material, _blendMode, n*4, 1 )

		For k = 0 to n
			AddPointVertex( x0+pointX[k], y0+pointY[k], 0,0 )
		Next
		
		For k = n To 0 Step -1
			AddPointVertex( x1r-pointX[k], y0+pointY[k], 0,0 )
		Next

		For k = 0 To n
			AddPointVertex( x1r-pointX[k], y1r-pointY[k], 0,0 )
		Next

		For k = n to 0 Step -1
			AddPointVertex( x0+pointX[k], y1r-pointY[k], 0,0 )
		Next
	End method

	
	method DrawFrameRoundedRect( x:float, y:float, width:float, height:float, radius:float )
'		canvas.DrawRect( x, y, width, height )
		Local n:float = radius * 0.75
		local pointX:float[] = New float[n]
		local pointY:float[] = New float[n]
		
		local x0:float = x + radius
		local y0:float = y + radius
		local px:float
		local py:float

		local div:float = (Pi*0.5) / n
		local theta:float = Pi
		n -= 1
		
		local k:int
		local k1:int
		For k = 0 to n
			pointX[k] = Cos( theta ) * radius
			pointY[k] = Sin( theta ) * radius
			theta += div
		Next
		
		local x1:float = x + width
		local x1r:float = x1 - radius
		local y1:float = y + height
		local y1r:float = y1 - radius

'		canvas.Color = Color.Yellow
		k1 = 1
		For k = 0 to n-1
			DrawLine( x0+pointX[k], y0+pointY[k], x0+pointX[k1], y0+pointY[k1] )
			k1 += 1
		Next

		k1 -= 1
		DrawLine( x0+pointX[k1], y0+pointY[k1], x1r-pointX[k1], y0+pointY[k1] )

		k1 = 1
		For k = 0 To n-1
			DrawLine( x1r-pointX[k], y0+pointY[k], x1r-pointX[k1], y0+pointY[k1] )
			k1 += 1
		Next

		k1 -= 1
		DrawLine( x1r-pointX[0], y0+pointY[0], x1r-pointX[0], y1r-pointY[0] )

		k1 = 1
		For k = 0 To n-1
			DrawLine( x1r-pointX[k], y1r-pointY[k], x1r-pointX[k1], y1r-pointY[k1] )
			k1 += 1
		Next

		k1 -= 1
		DrawLine( x0+pointX[k1], y1r-pointY[k1], x1r-pointX[k1], y1r-pointY[k1] )

		k1 = 1
		For k = 0 to n-1
			DrawLine( x0+pointX[k], y1r-pointY[k], x0+pointX[k1], y1r-pointY[k1] )
			k1 += 1
		Next

		k1 -= 1
		DrawLine( x0+pointX[0], y1r-pointY[0], x0+pointX[0], y0-pointY[0] )
	End method

	
	Method DrawChamferRect( x:Float, y:Float, w:Float, h:Float, c:float )
		Local x0:float = x
		local y0:float = y
		local x1:float = x+w
		local y1:float = y+h
		
		local cx0:float = x0 + c
		local cx1:float = x1 - c
		local cy0:float = y0 + c
		local cy1:float = y1 - c
		
		local u0:float = w / c
		local v0:float = h / c
		local u1:float = w - u0
		local v1:float = h - v0
		
		AddDrawOp( _shader, _material, _blendMode, 8, 1 )
		
		AddVertex( cx0, y0, u0, 0 )
		AddVertex( cx1, y0, u1, 0 )
		AddVertex( x1, cy0, 1, v0 )
		AddVertex( x1, cy1, 1, v1 )
		AddVertex( cx1, y1, u1, 1 )
		AddVertex( cx0, y1, u0, 1 )
		AddVertex( x0, cy1, 0, v1 )
		AddVertex( x0, cy0, 0, v0 )

'		AddVertex( x0, y0, 0, 0 )
'		AddVertex( x1, y0, 1, 0 )
'		AddVertex( x1, y1, 1, 1 )
'		AddVertex( x0, y1, 0, 1 )
	End

	Method DrawFrameChamferRect( x:Float, y:Float, w:Float, h:Float, c:float )
		Local x0:float = x
		local y0:float = y
		local x1:float = x+w
		local y1:float = y+h
		
		local cx0:float = x0 + c
		local cx1:float = x1 - c
		local cy0:float = y0 + c
		local cy1:float = y1 - c
		
'		local u0:float = w / c
'		local v0:float = h / c
'		local u1:float = w - u0
'		local v1:float = h - v0
		
		DrawLine( cx0, y0, cx1, y0 )
		DrawLine( cx1, y0, x1, cy0 )
		DrawLine( x1, cy0, x1, cy1 )
		DrawLine( x1, cy1, cx1, y1 )
		DrawLine( cx1, y1, cx0, y1 )
		DrawLine( cx0, y1, x0, cy1 )
		DrawLine( x0, cy1, x0, cy0 )
		DrawLine( x0, cy0, cx0, y0 )
				
		
'		AddDrawOp( _shader,_material,_blendMode,4,1 )
		
'		AddVertex( cx0, y0, u0, 0 )
'		AddVertex( cx1, y0, u1, 0 )
'		AddVertex( x1, cy0, 1, v0 )
'		AddVertex( x1, cy1, 1, v1 )
'		AddVertex( cx1, y1, u1, 1 )
'		AddVertex( cx0, y1, u0, 1 )
'		AddVertex( x0, cy1, 0, v1 )
'		AddVertex( x0, cy0, 0, v0 )

'		AddVertex( x0, y0, 0, 0 )
'		AddVertex( x1, y0, 1, 0 )
'		AddVertex( x1, y1, 1, 1 )
'		AddVertex( x0, y1, 0, 1 )
	End

	Method DrawCross( x:Float, y:Float, w:Float )
		Local x0 := x-w
		Local y0 := y-w
		Local x1 := x+w
		Local y1 := y+w
		
		DrawLine( x0, y, x1, y )
		DrawLine( x, y0, x, y1 )
	End

	Method DrawX( x:Float, y:Float, w:Float )
		Local x0 := x-w
		Local y0 := y-w
		Local x1 := x+w
		Local y1 := y+w
		
		DrawLine( x0, y0, x1, y1 )
		DrawLine( x1, y0, x0, y1 )
	End

	Method DrawTarget( x:Float, y:Float, w1:Float, w2:float )
		Local x0 := x-w1
		Local y0 := y-w1
		Local x1 := x+w1
		Local y1 := y+w1
		
		Local x2 := x-w2
		Local y2 := y-w2
		Local x3 := x+w2
		Local y3 := y+w2

		DrawLine( x2, y, x0, y )
		DrawLine( x3, y, x1, y )
		DrawLine( x, y2, x, y0 )
		DrawLine( x, y3, x, y1 )
	End

	Method DrawTriangle( x:Float, y:Float, w:Float, angle:float = 0 )
		local x0:float = x + Sin(angle) * w
		local y0:float = y + Cos(angle) * w
		angle += Pi * .666666
		local x1:float = x + Sin(angle) * w
		local y1:float = y + Cos(angle) * w
		angle += Pi * .666666
		local x2:float = x + Sin(angle) * w
		local y2:float = y + Cos(angle) * w
		
		AddDrawOp( _shader, _material, _blendMode, 3, 1 )
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,1,0 )
		AddVertex( x2,y2,1,1 )
	End

	Method DrawFrameTriangle( x:Float, y:Float, w:Float, angle:float = 0 )
		local x0:float = x + Sin(angle) * w
		local y0:float = y + Cos(angle) * w
		angle += Pi * .666666
		local x1:float = x + Sin(angle) * w
		local y1:float = y + Cos(angle) * w
		angle += Pi * .666666
		local x2:float = x + Sin(angle) * w
		local y2:float = y + Cos(angle) * w
		
		DrawLine( x0, y0, x1, y1)
		DrawLine( x1, y1, x2, y2)
		DrawLine( x2, y2, x0, y0)
	End

	Method DrawFrameDiamond( x:Float, y:Float, w:Float )
		Local x0 := x-w
		Local y0 := y-w
		Local x1 := x+w
		Local y1 := y+w
		
		DrawLine( x0, y, x, y0 )
		DrawLine( x, y0, x1, y )
		DrawLine( x1, y, x, y1 )
		DrawLine( x, y1, x0, y )
		DrawPoint(x0, y)
	End

	Method DrawDiamond( x:Float, y:Float, w:Float )
		Local x0 := x-w
		Local y0 := y-w
		Local x1 := x+w
		Local y1 := y+w
		
		AddDrawOp( _shader,_material,_blendMode,4,1 )
		
		AddVertex( x0, y, 0,0 )
		AddVertex( x, y0, 1,0 )
		AddVertex( x1,y,  1,1 )
		AddVertex( x,y1,  0,1 )
	End

	Method DrawFrameSquare( x:Float, y:Float, w:Float )
		Local x0 := x-w
		Local y0 := y-w
		Local x1 := x+w
		Local y1 := y+w
		
		DrawLine( x0, y0, x1, y0 )
		DrawLine( x1, y0, x1, y1 )
		DrawLine( x1, y1, x0, y1 )
		DrawLine( x0, y1, x0, y0 )
		DrawPoint(x0, y0)
	End

	Method DrawSquare( x:Float, y:Float, w:Float )
		Local x0 := x-w
		Local y0 := y-w
		Local x1 := x+w
		Local y1 := y+w
		
		AddDrawOp( _shader,_material,_blendMode,4,1 )
		
		AddVertex( x0, y0, 0,0 )
		AddVertex( x1, y0, 1,0 )
		AddVertex( x1, y1,  1,1 )
		AddVertex( x0, y1,  0,1 )
	End

	Method DrawSquare( x:Float, y:Float, w:Float, srcImage:Image, shader:Shader, material:UniformBlock )
		If Not shader Then
			DrawSquare( x, y, w )
			Return
		End If

		Local x0 := x-w
		Local y0 := y-w
'		Local x1 := x+w
'		Local y1 := y+w
		w += w
		
		DrawRect( x0, y0, w, w, srcImage, shader, material )
	End

	#rem monkeydoc Draws a rectangle frame (made from lines).
	Draws a rectangleline in the current [[Color]] using the current [[BlendMode]].
	The rectangle vertex coordinates are also transform by the current [[Matrix]].
	#end
	Method DrawFrame( x:Float, y:Float, w:Float, h:Float )
	
		Local x0 := x
		Local y0 := y
		Local x1 := x+w-1
		Local y1 := y+h-1
		
		DrawLine( x0, y0, x1, y0 )
		DrawLine( x0, y0, x0, y1 )
		DrawLine( x1, y0, x1, y1 )
		DrawLine( x0, y1, x1, y1 )
		DrawPoint(x1, y1)
	End

	Method DrawFrame3d( x:Float, y:Float, w:Float, h:Float )
		Local x0 := x
		Local y0 := y
		Local x1 := x+w-1
		Local y1 := y+h-1
		
		local colStore:Color = _color
		
		Color = Color.White * 0.5
		DrawLine( x0, y0, x1, y0 )
		DrawLine( x0, y0, x0, y1 )
		Color = Color.Black * 0.5
		DrawLine( x1, y0, x1, y1 )
		DrawLine( x0, y1, x1, y1 )
		DrawPoint(x1, y1)
		
		Color = colStore
	End

	Method DrawColorRect( x:Float,y:Float,w:Float,h:Float )
		local colStore:Color = _color

		Color = Color.Black
		DrawFrame( x, y, w, h )

		Color = Color.White
		DrawFrame( x+1, y+1, w-2, h-2 )

		Color = colStore
		DrawRect( x+2, y+2, w-4, h-4 )
	End

	Method DrawTriangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color0:Uint, color1:Uint, color2:Uint )
		AddDrawOp( _shader, _material, _blendMode,3,1 )

		AddVertex( x0,y0, 0,0, color0 )
		AddVertex( x1,y1, 1,0, color1 )
		AddVertex( x2,y2, 1,1, color2 )
	End

	Method DrawTriangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, color0:Color, color1:Color, color2:Color )
		AddDrawOp( _shader, _material, _blendMode,3,1 )

'		local pmcolor:UInt = _pmcolor
		local col0:uint = UInt(color0.a*255) Shl 24 | UInt(color0.b*255) Shl 16 | UInt(color0.g*255) Shl 8 | UInt(color0.r*255)
		local col1:uint = UInt(color1.a*255) Shl 24 | UInt(color1.b*255) Shl 16 | UInt(color1.g*255) Shl 8 | UInt(color1.r*255)
		local col2:uint = UInt(color2.a*255) Shl 24 | UInt(color2.b*255) Shl 16 | UInt(color2.g*255) Shl 8 | UInt(color2.r*255)

		AddVertex( x0,y0, 0,0, col0 )
		AddVertex( x1,y1, 1,0, col1 )
		AddVertex( x2,y2, 1,1, col2 )

'		_pmcolor = pmcolor
	End

	Method DrawTriangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
						 col0:UInt, col1:UInt, col2:Uint,
						 u0:float, v0:float, u1:float, v1:float, u2:float, v2:float )
		AddDrawOp( _shader, _material, _blendMode, 3,1 )

		AddVertex( x0,y0, u0,v0, col0 )
		AddVertex( x1,y1, u1,v1, col1 )
		AddVertex( x2,y2, u2,v2, col2 )
	End

	Method DrawTriangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
						 col0:UInt, col1:UInt, col2:Uint,
						 srcImage:Image, shader:Shader, material:UniformBlock )
		AddDrawOp( shader, material, srcImage.BlendMode, 3,1 )

		AddVertex( x0,y0, 0,0, col0 )
		AddVertex( x1,y1, 1,0, col1 )
		AddVertex( x2,y2, 1,1, col2 )
	End

	Method DrawTriangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
						 col0:UInt, col1:UInt, col2:Uint,
						 u0:float, v0:float, u1:float, v1:float, u2:float, v2:float, 
						 srcImage:Image, shader:Shader, material:UniformBlock )
		AddDrawOp( shader, material, srcImage.BlendMode, 3,1 )

		AddVertex( x0,y0, u0,v0, col0 )
		AddVertex( x1,y1, u1,v1, col1 )
		AddVertex( x2,y2, u2,v2, col2 )
	End

	Method DrawTriangle( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
						 col0:UInt, col1:UInt, col2:Uint,
						 u0:float, v0:float, u1:float, v1:float, u2:float, v2:float, 
						 srcImage:Image, shader:Shader )
		AddDrawOp( shader, srcImage.Material, srcImage.BlendMode,3,1 )

		AddVertex( x0,y0, u0,v0, col0 )
		AddVertex( x1,y1, u1,v1, col1 )
		AddVertex( x2,y2, u2,v2, col2 )
	End

	Method DrawTriangleXYZ( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
						 col0:UInt, col1:UInt, col2:Uint,
						 u0:float, v0:float, u1:float, v1:float, u2:float, v2:float, 
						 srcImage:Image, shader:Shader, material:UniformBlock, 
						 xp0:float, yp0:float, zp0:float, 
						 xp1:float, yp1:float, zp1:float, 
						 xp2:float, yp2:float, zp2:float  )
		AddDrawOp( shader, material, srcImage.BlendMode, 3,1 )

		AddVertex( x0,y0,  u0,v0,  col0,  xp0,yp0,zp0 )
		AddVertex( x1,y1,  u1,v1,  col1,  xp1,yp1,zp1 )
		AddVertex( x2,y2,  u2,v2,  col2,  xp2,yp2,zp2 )
	End

	Method DrawTriangleXYZNormal( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
						 col0:UInt, col1:UInt, col2:Uint,
						 u0:float, v0:float, u1:float, v1:float, u2:float, v2:float, 
						 srcImage:Image, shader:Shader, material:UniformBlock, 
						 xp0:float, yp0:float, zp0:float,
						 xp1:float, yp1:float, zp1:float,
						 xp2:float, yp2:float, zp2:float,
						 nx:float, ny:float, nz:float )
		AddDrawOp( shader, material, srcImage.BlendMode, 3,1 )

		AddVertexNormal( x0,y0,  u0,v0,  col0,  xp0,yp0,zp0,  nx,ny,nz )
		AddVertexNormal( x1,y1,  u1,v1,  col1,  xp1,yp1,zp1,  nx,ny,nz )
		AddVertexNormal( x2,y2,  u2,v2,  col2,  xp2,yp2,zp2,  nx,ny,nz )
	End

	Method DrawTriangleXYZNormal2( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float,
						 col0:UInt, col1:UInt, col2:Uint,
						 u0:float, v0:float, u1:float, v1:float, u2:float, v2:float, 
						 u10:float, v10:float, u11:float, v11:float, u12:float, v12:float, 
						 srcImage:Image, shader:Shader, material:UniformBlock, 
						 xp0:float, yp0:float, zp0:float,
						 xp1:float, yp1:float, zp1:float,
						 xp2:float, yp2:float, zp2:float,
						 nx:float, ny:float, nz:float )
		AddDrawOp( shader, material, srcImage.BlendMode, 3,1 )

		AddVertexNormal2( x0,y0,  u0,v0,  u10,v10,  col0,  xp0,yp0,zp0,  nx,ny,nz )
		AddVertexNormal2( x1,y1,  u1,v1,  u11,v11,  col1,  xp1,yp1,zp1,  nx,ny,nz )
		AddVertexNormal2( x2,y2,  u2,v2,  u12,v12,  col2,  xp2,yp2,zp2,  nx,ny,nz )
	End


	Method DrawRect( rect:Rectf, srcImage:Image, shader:Shader )
		If Not shader Then
			DrawRect( rect, srcImage )
			Return
		End If
		Local tc := srcImage.TexCoords
		AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 4, 1 )
		AddVertex( rect.min.x, rect.min.y, tc.min.x, tc.min.y )
		AddVertex( rect.max.x, rect.min.y, tc.max.x, tc.min.y )
		AddVertex( rect.max.x, rect.max.y, tc.max.x, tc.max.y )
		AddVertex( rect.min.x, rect.max.y, tc.min.x, tc.max.y )
	End

	Method DrawRect( x:Float,y:Float,width:Float,height:Float, srcImage:Image, shader:Shader )
		If Not shader Then
			DrawRect( New Rectf( x,y,x+width,y+height ), srcImage )
			Return
		End If
		DrawRect( New Rectf( x,y,x+width,y+height ), srcImage, shader )
	End


	Method DrawRect( rect:Rectf, srcImage:Image, shader:Shader, material:UniformBlock )
		If Not shader Then
			DrawRect( rect, srcImage )
			Return
		End If
		Local tc:=srcImage.TexCoords
		AddDrawOp( shader, material, srcImage.BlendMode, 4, 1 )
		AddVertex( rect.min.x,rect.min.y,tc.min.x,tc.min.y )
		AddVertex( rect.max.x,rect.min.y,tc.max.x,tc.min.y )
		AddVertex( rect.max.x,rect.max.y,tc.max.x,tc.max.y )
		AddVertex( rect.min.x,rect.max.y,tc.min.x,tc.max.y )
	End

	Method DrawRect( x:Float,y:Float,width:Float,height:Float, srcImage:Image, shader:Shader, material:UniformBlock )
		If Not shader Then
			DrawRect( New Rectf( x,y,x+width,y+height ), srcImage )
			Return
		End If
		DrawRect( New Rectf( x,y,x+width,y+height ), srcImage, shader, material )
	End


	Method DrawHFadeRect( x:Float, y:Float, w:Float, h:Float, colLeft:Color, colRight:Color )
		Local x0 := x
		Local y0 := y
		Local x1 := x+w
		Local y1 := y+h
	
		AddDrawOp( _shader, _material, _blendMode, 4, 1 )

		local pmcolor:UInt = _pmcolor
		
		local colL:uint = UInt(colLeft.a*255) Shl 24 | UInt(colLeft.b*255) Shl 16 | UInt(colLeft.g*255) Shl 8 | UInt(colLeft.r*255)
		local colR:uint = UInt(colRight.a*255) Shl 24 | UInt(colRight.b*255) Shl 16 | UInt(colRight.g*255) Shl 8 | UInt(colRight.r*255)
		
		_pmcolor = colL
		AddVertex( x0,y0, 0,0 )
		_pmcolor = colR
		AddVertex( x1,y0, 1,0 )
		AddVertex( x1,y1, 1,1 )
		_pmcolor = colL
		AddVertex( x0,y1, 0,1 )

		_pmcolor = pmcolor
	End

	Method DrawVFadeRect( x:Float, y:Float, w:Float, h:Float, colTop:Color, colBottom:Color )
		Local x0 := x
		Local y0 := y
		Local x1 := x+w
		Local y1 := y+h
	
		AddDrawOp( _shader, _material, _blendMode, 4, 1 )

		local pmcolor:UInt = _pmcolor

		local colT:uint = UInt(colTop.a*255) Shl 24 | UInt(colTop.b*255) Shl 16 | UInt(colTop.g*255) Shl 8 | UInt(colTop.r*255)
		local colB:uint = UInt(colBottom.a*255) Shl 24 | UInt(colBottom.b*255) Shl 16 | UInt(colBottom.g*255) Shl 8 | UInt(colBottom.r*255)
		
		AddVertex( x0,y0, 0,0, colT )
		AddVertex( x1,y0, 1,0, colT )
		AddVertex( x1,y1, 1,1, colB )
		AddVertex( x0,y1, 0,1, colB )

		_pmcolor = pmcolor
	End

	#rem monkeydoc Draws a quad from a source image.

	The source image is used and drawn at the given quad position in the current [[Color]] using the current [[BlendMode]].
	
	The quad vertex coordinates are also transformed by the current [[Matrix]].

	#end
	Method DrawQuadImage( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image )
'		Local vs:=image.Vertices
'		Local ts:=image.TexCoords
'		
'		AddDrawOp( image.Shader,image.Material,image.BlendMode,4,1 )
'		
'		AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y )
'		AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y )
'		AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y )
'		AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y )
		
'		If _lighting And image.ShadowCaster
'			AddShadowCaster( image.ShadowCaster,tx,ty )
'		Endif


'		AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,1 )
'		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, srcImage.TextureFilter, 4,1 )
		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 4,1 )
'		AddDrawOp( srcImage.Material, 4, 1 )
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,1,0 )
		AddVertex( x2,y2,1,1 )
		AddVertex( x3,y3,0,1 )
	End

	Method DrawQuadImage( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image, shader:Shader )
		AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 4,1 )

		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,1,0 )
		AddVertex( x2,y2,1,1 )
		AddVertex( x3,y3,0,1 )
	End method

	Method DrawQuadIntersectImage( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image )
		LineIntersect( x0, y0, x2, y2,  x1, y1, x3, y3 )

		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 3,1 )
		AddVertex( x0,y0, 0,0 )
		AddVertex( x1,y1, 1,0 )
		AddVertex( _iX,_iY, 0.5,0.5 )

		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 3,1 )
		AddVertex( x1,y1, 1,0 )
		AddVertex( x2,y2, 1,1 )
		AddVertex( _iX,_iY, 0.5,0.5 )

		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 3,1 )
		AddVertex( x2,y2, 1,1 )
		AddVertex( x3,y3, 0,1 )
		AddVertex( _iX,_iY, 0.5,0.5 )

		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 3,1 )
		AddVertex( x3,y3, 0,1 )
		AddVertex( x0,y0, 0,0 )
		AddVertex( _iX,_iY, 0.5,0.5 )
	End

	Method DrawQuadIntersectImage( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image, shader:Shader )
		LineIntersect( x0, y0, x2, y2,  x1, y1, x3, y3 )

		AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 3,1 )
		AddVertex( x0,y0, 0,0 )
		AddVertex( x1,y1, 1,0 )
		AddVertex( _iX,_iY, 0.5,0.5 )

		AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 3,1 )
		AddVertex( x1,y1, 1,0 )
		AddVertex( x2,y2, 1,1 )
		AddVertex( _iX,_iY, 0.5,0.5 )

		AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 3,1 )
		AddVertex( x2,y2, 1,1 )
		AddVertex( x3,y3, 0,1 )
		AddVertex( _iX,_iY, 0.5,0.5 )

		AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 3,1 )
		AddVertex( x3,y3, 0,1 )
		AddVertex( x0,y0, 0,0 )
		AddVertex( _iX,_iY, 0.5,0.5 )
	End

	'line intersection
	field _iX:double
	field _iY:double
	method LineIntersect( ax1:float, ay1:float, ax2:float, ay2:float, bx1:float, by1:float, bx2:float, by2:float )
		local dx:double = ax2 - ax1
		local dy:double = ay2 - ay1
		
		local m1:double = dy / dx
		' y = mx + c
		' intercept c = y - mx
		local c1:double = ay1 - m1 * ax1 ' which is same as y2 - slope * x2
		
		dx = bx2 - bx1
		dy = by2 - by1
		
		local m2:double = dy / dx
		local c2:double = by2 - m2 * bx2 'which is same as y2 - slope * x2

		if m1 - m2 = 0 Then
			_iX = -1
			_iY = -1
'			Print "No Intersection between the lines"
		Else
			_iX = (c2 - c1) / (m1 - m2)
			_iY = m1 * _iX + c1
'			Print "intersection:"+ iX+" "+iY
		End If
	End method
	
	#rem monkeydoc Draws a quad from a source image.

	The source image is used and drawn at the given quad position in the current [[Color]] using the current [[BlendMode]].
	
	The quad vertex coordinates are also transformed by the current [[Matrix]].

	#end
	Method DrawQuadImageIcon( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image, iconNumber:Int, iconCount:Int )
		If iconCount < 0 Then Return
    
		Local vs := srcImage.Vertices
		Local wd:double = (vs.max.x - vs.min.x) / iconCount
		'vs.max.x = vs.min.x + wd

		Local tc := srcImage.TexCoords
		wd = (tc.max.x - tc.min.x) / iconCount
		tc.min.x = tc.min.x + (iconNumber * wd)
		tc.max.x = tc.min.x + wd


		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 4,1 )
'		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, srcImage.TextureFilter, 4,1 )
'		AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,1 )
'		AddDrawOp( srcImage.Material, 4, 1 )
		AddVertex( x0, y0,  tc.min.x, tc.min.y )
		AddVertex( x1, y1,  tc.max.x, tc.min.y )
		AddVertex( x2, y2,  tc.max.x, tc.max.y )
		AddVertex( x3, y3,  tc.min.x, tc.max.y )

'		AddVertex( x0,y0,0,0 )
'		AddVertex( x1,y1,1,0 )
'		AddVertex( x2,y2,1,1 )
'		AddVertex( x3,y3,0,1 )
	End

	
	#rem monkeydoc Draws a quad from a source image slice.

	The source image is used and drawn at the given quad position in the current [[Color]] using the current [[BlendMode]].
	
	The quad vertex coordinates are also transformed by the current [[Matrix]].

	#end
	Method DrawQuadImageSlice( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcVoxImage:ImageSlice, sliceNumber:Int, FrameNumber:Int )
		If Not srcVoxImage Then Return
		
		If not srcVoxImage._sliceLive[ FrameNumber, sliceNumber ] Then return

		
'		Local tc:Rectf = srcVoxImage.Image.TexCoords
'		local frameWidth:double = (tc.max.x - tc.min.x) / srcVoxImage.FrameCount
'		Local wd:double = frameWidth / srcVoxImage.SliceXCount
'		Local ht:double = 1.0 / srcVoxImage.SliceYCount

'		tc.min.x = tc.min.x + ((sliceNumber Mod srcVoxImage.SliceXCount) * wd) + (frameWidth * FrameNumber)
'		tc.max.x = tc.min.x + wd

'		tc.min.y = tc.min.y + (int(sliceNumber / srcVoxImage.SliceXCount) * ht)
'		tc.max.y = tc.min.y + ht

'		tc.min.x += 0.0001
'		tc.max.x -= 0.0001
'		tc.min.y += 0.0001
'		tc.max.y -= 0.0001

		Local tc:Rectf = srcVoxImage._sliceTexCoords[ FrameNumber, sliceNumber ]
		
		AddDrawOp( srcVoxImage.Image.Shader, srcVoxImage.Image.Material, srcVoxImage.Image.BlendMode, 4,1 )
'		AddDrawOp( srcVoxImage.Image.Shader, srcVoxImage.Image.Material, srcVoxImage.Image.BlendMode, srcVoxImage.Image.TextureFilter, 4,1 )

		AddVertex( x0, y0,  tc.min.x, tc.min.y )
		AddVertex( x1, y1,  tc.max.x, tc.min.y )
		AddVertex( x2, y2,  tc.max.x, tc.max.y )
		AddVertex( x3, y3,  tc.min.x, tc.max.y )


	End
	

	#rem monkeydoc Draws an image icon frame.
	Draws an image using the current [[Color]], [[BlendMode]] and [[Matrix]].

	@param tx X coordinate to draw image at.

	@param ty Y coordinate to draw image at.

	@param tx1 X1 coordinate to draw image to.

	@param ty1 Y1 coordinate to draw image to.

	@param iconNumber number from 0 of the icon frame to draw (frames start from 0 and go left to right in equal pixel amounts).

	@param iconCount how many icon frames are packed into the image

	@param sx X axis scale factor for drawing.

	@param sy Y axis scale factor for drawing.

	@param rotate (in radians) of the icon. 0 = no rotation
  #end
	Method DrawImageIcon( image:Image, tx:Float, ty:Float, iconNumber:Int, iconCount:Int, rotate:float = 0 )
		If iconCount < 0 Then Return
    
		Local vs:=image.Vertices
		Local wd:double = (vs.max.x - vs.min.x) / iconCount
		vs.max.x = vs.min.x + wd

		Local tc:=image.TexCoords
		wd = (tc.max.x - tc.min.x) / iconCount
		tc.min.x = tc.min.x + (iconNumber * wd)
		tc.max.x = tc.min.x + wd
		
		If rotate <> 0 Then
			Local x:float = vs.min.x
			Local x1:float = vs.max.x
			Local y:float = vs.min.y
			Local y1:float = vs.max.y

			Local xm:float = (x1 + x) * .5
			Local ym:float = (y1 + y) * .5
			
			x -= xm
			y -= ym
			x1 -= xm
			y1 -= ym

			Local x2:float = x1
			Local y2:float = y1
			Local x3:float = x
			Local y3:float = y1
			x1 = x1
			y1 = y
			
			AddDrawOp( image.Shader, image.Material, image.BlendMode, 4,1 )
'			AddDrawOp( image.Shader, image.Material, image.BlendMode, image.TextureFilter, 4,1 )
'			AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,1 )
'			AddDrawOp( image.Material,4,1 )
			AddVertex( x + tx, y + ty,  tc.min.x, tc.min.y )
			AddVertex( x1 + tx, y1 + ty,  tc.max.x, tc.min.y )
			AddVertex( x2 + tx, y2 + ty,  tc.max.x, tc.max.y )
			AddVertex( x3 + tx, y3 + ty,  tc.min.x, tc.max.y )

		Else	
			Local x:float = vs.min.x + tx
			Local x1:float = vs.max.x + tx
			Local y:float = vs.min.y + ty
			Local y1:float = vs.max.y + ty

			AddDrawOp( image.Shader, image.Material, image.BlendMode, 4,1 )
'			AddDrawOp( image.Shader, image.Material, image.BlendMode, image.TextureFilter, 4,1 )
'			AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,1 )
'			AddDrawOp( image.Material,4,1 )
			AddVertex( x, y,  tc.min.x, tc.min.y )
			AddVertex( x1, y,  tc.max.x, tc.min.y )
			AddVertex( x1, y1,  tc.max.x, tc.max.y )
			AddVertex( x, y1,  tc.min.x, tc.max.y )
		End If
		
	End


	Method DrawImageIconSize( image:Image, tx:Float, ty:Float, tx1:int, ty1:int, iconNumber:Int, iconCount:Int )
		If iconCount < 0 Then Return
    
		Local vs:=image.Vertices
		Local wd:double = (vs.max.x - vs.min.x) / iconCount
		vs.max.x = vs.min.x + wd

		Local tc:=image.TexCoords
		wd = (tc.max.x - tc.min.x) / iconCount
		tc.min.x = tc.min.x + (iconNumber * wd)
		tc.max.x = tc.min.x + wd
		
		Local x:float = vs.min.x + tx
		Local x1:float = tx1 + tx
		Local y:float = vs.min.y + ty
		Local y1:float = ty1 + ty

		AddDrawOp( image.Shader, image.Material, image.BlendMode, 4,1 )
'		AddDrawOp( image.Shader, image.Material, image.BlendMode, image.TextureFilter, 4,1 )
'		AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,1 )
'		AddDrawOp( image.Material,4,1 )
		AddVertex( x, y,  tc.min.x, tc.min.y )
		AddVertex( x1, y,  tc.max.x, tc.min.y )
		AddVertex( x1, y1,  tc.max.x, tc.max.y )
		AddVertex( x, y1,  tc.min.x, tc.max.y )
		
	End


	Method DrawImageIcon( image:Image, tx:Float, ty:Float, iconNumber:Int, iconCount:Int, sx:Float, sy:float )
		Local matrix := _matrix
		Translate( tx, ty )
		Scale( sx, sy )
		Rotate( 0 )
		
		DrawImageIcon( image, 0,0, iconNumber, iconCount )
		
		_matrix = matrix
	End

	Method DrawImageIconRotate( image:Image, tx:Float, ty:Float, iconNumber:Int, iconCount:Int, rot:float, sx:Float, sy:float )
		If iconCount < 0 Then Return

		Local matrix := _matrix
		Translate( tx, ty )
		Scale( sx, sy )
		Rotate( rot )
		
		DrawImageIcon( image, 0,0, iconNumber, iconCount, rot )
		
		_matrix = matrix
	End

	Method DrawImageRect( x:Float, y:Float, x1:Float, y1:Float, srcImage:Image, srcX:Int, srcY:Int, srcX1:Int, srcY1:Int )
		local srcRect := New Recti( srcX, srcY, srcX1, srcY1 )
		Local s0 := Float( srcImage.Rect.min.x + srcRect.min.x ) / srcImage.Texture.Width
		Local t0 := Float( srcImage.Rect.min.y + srcRect.min.y ) / srcImage.Texture.Height
		Local s1 := Float( srcImage.Rect.min.x + srcRect.max.x ) / srcImage.Texture.Width
		Local t1 := Float( srcImage.Rect.min.y + srcRect.max.y ) / srcImage.Texture.Height

		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 4,1 )
'		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, srcImage.TextureFilter, 4,1 )
'		AddDrawOp( _shader,_material,_blendMode,_textureFilter,4,1 )
'		AddDrawOp( srcImage.Material, 4, 1 )
		AddVertex( x, y, s0, t0 )
		AddVertex( x1, y, s1, t0 )
		AddVertex( x1, y1, s1, t1 )
		AddVertex( x, y1, s0, t1 )
	End

	Method DrawImageQuad( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image, srcX:Int, srcY:Int, srcX1:Int, srcY1:Int, inset:float = 0.0015 )
		Local wd:double = 1.0 / float(srcImage.Width)
		Local ht:double = 1.0 / float(srcImage.Height)
		
		local tx0:double = (wd * srcX) +inset
		local ty0:double = (ht * srcY) +inset
		local tx1:double = (wd * srcX1) -inset
		local ty1:double = (ht * srcY1) -inset
		
		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 4,1 )

		AddVertex( x0, y0,  tx0, ty0 )
		AddVertex( x1, y1,  tx1, ty0 )
		AddVertex( x2, y2,  tx1, ty1 )
		AddVertex( x3, y3,  tx0, ty1 )
	End

	Method DrawImageQuad( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image, srcX:Int, srcY:Int, srcX1:Int, srcY1:Int, shader:Shader, inset:float = 0.0015 )
		Local wd:double = 1.0 / float(srcImage.Width)
		Local ht:double = 1.0 / float(srcImage.Height)
		
		local tx0:double = (wd * srcX) +inset
		local ty0:double = (ht * srcY) +inset
		local tx1:double = (wd * srcX1) -inset
		local ty1:double = (ht * srcY1) -inset
		
		AddDrawOp( shader, srcImage.Material, srcImage.BlendMode, 4,1 )

		AddVertex( x0, y0,  tx0, ty0 )
		AddVertex( x1, y1,  tx1, ty0 )
		AddVertex( x2, y2,  tx1, ty1 )
		AddVertex( x3, y3,  tx0, ty1 )
	End

	Method DrawImageQuad( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image, srcX:Int, srcY:Int, srcX1:Int, srcY1:Int, shader:Shader, mat:UniformBlock, inset:float = 0.0015 )
		Local wd:double = 1.0 / float(srcImage.Width)
		Local ht:double = 1.0 / float(srcImage.Height)
		
		local tx0:double = (wd * srcX) +inset
		local ty0:double = (ht * srcY) +inset
		local tx1:double = (wd * srcX1) -inset
		local ty1:double = (ht * srcY1) -inset
		
		AddDrawOp( shader, mat, srcImage.BlendMode, 4,1 )

		AddVertex( x0, y0,  tx0, ty0 )
		AddVertex( x1, y1,  tx1, ty0 )
		AddVertex( x2, y2,  tx1, ty1 )
		AddVertex( x3, y3,  tx0, ty1 )
	End

	Method DrawImageQuadPure( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image, srcX:Int, srcY:Int, srcX1:Int, srcY1:Int )
		Local wd:double = 1.0 / float(srcImage.Width)
		Local ht:double = 1.0 / float(srcImage.Height)
		
		local tx0:double = (wd * srcX)
		local ty0:double = (ht * srcY)
		local tx1:double = (wd * srcX1)
		local ty1:double = (ht * srcY1)
		
		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, 4,1 )
'		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, srcImage.TextureFilter, 4,1 )

		AddVertex( x0, y0,  tx0, ty0 )
		AddVertex( x1, y1,  tx1, ty0 )
		AddVertex( x2, y2,  tx1, ty1 )
		AddVertex( x3, y3,  tx0, ty1 )
	End

	Method DrawImageQuadPure( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image, srcX:Int, srcY:Int, srcX1:Int, srcY1:Int, fx:Shader )
		Local wd:double = 1.0 / float(srcImage.Width)
		Local ht:double = 1.0 / float(srcImage.Height)
		
		local tx0:double = (wd * srcX)
		local ty0:double = (ht * srcY)
		local tx1:double = (wd * srcX1)
		local ty1:double = (ht * srcY1)
		
		AddDrawOp( fx, srcImage.Material, srcImage.BlendMode, 4,1 )
'		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, srcImage.TextureFilter, 4,1 )

		AddVertex( x0, y0,  tx0, ty0 )
		AddVertex( x1, y1,  tx1, ty0 )
		AddVertex( x2, y2,  tx1, ty1 )
		AddVertex( x3, y3,  tx0, ty1 )
	End

	Method DrawImageQuadPure( x0:Float, y0:Float, x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float, srcImage:Image, srcX:Int, srcY:Int, srcX1:Int, srcY1:Int, fx:Shader, mat:UniformBlock )
		Local wd:double = 1.0 / float(srcImage.Width)
		Local ht:double = 1.0 / float(srcImage.Height)
		
		local tx0:double = (wd * srcX)
		local ty0:double = (ht * srcY)
		local tx1:double = (wd * srcX1)
		local ty1:double = (ht * srcY1)
		
		AddDrawOp( fx, mat, srcImage.BlendMode, 4,1 )
'		AddDrawOp( srcImage.Shader, srcImage.Material, srcImage.BlendMode, srcImage.TextureFilter, 4,1 )

		AddVertex( x0, y0,  tx0, ty0 )
		AddVertex( x1, y1,  tx1, ty0 )
		AddVertex( x2, y2,  tx1, ty1 )
		AddVertex( x3, y3,  tx0, ty1 )
	End

	Method SetUserUniformCallback(callback:Void(canvas:Canvas, uniforms:UniformBlock))
		_userUniformCallback = callback
	End
	
	method SetCol2( r:uint, g:uint, b:uint, a:uint = 255 )
		_pmcolor2 = UInt(a) Shl 24 | UInt(b) Shl 16 | UInt(g) Shl 8 | UInt(r)
	End method

	method SetCol2( color:Color )
		_pmcolor2 = UInt(_color2.a) Shl 24 | UInt(_color2.b) Shl 16 | UInt(_color2.g) Shl 8 | UInt(_color2.r)
	End method

	method SetXYZ( x:float,  y:float,  z:float )
		_xyzPosition.x = x
		_xyzPosition.y = y
		_xyzPosition.z = z
	End method
	
	
	Property Color2:Color()
		Return _color2
	
	Setter( color2:Color )
		_color2=color2
		
		_pmcolor2=UInt(_color2.a) Shl 24 | UInt(_color2.b) Shl 16 | UInt(_color2.g) Shl 8 | UInt(_color2.r)
	End

'end of jeanluc additions
'------------------------------------------------------------

	
	#rem monkeydoc Creates a canvas that renders to an image
	#end
	Method New( image:Image )
		
		Local rtarget:=New RenderTarget( New Texture[]( image.Texture ),Null )
		
		Init( rtarget,New GraphicsDevice )
		
		BeginRender( New Recti( 0,0,image.Rect.Size ),AffineMat3f.Translation( image.Rect.Origin ) )
	End

	#rem monkeydoc @hidden Creates a canvas that renders to the backbuffer.
	#end	
	Method New( width:Int,height:Int )
		
		Init( Null,New GraphicsDevice( width,height ) )
	End

	#rem monkeydoc @hidden Resizes a canvas that renders to the backbuffer.
	#end	
	Method Resize( size:Vec2i )
		
		_device.Resize( size )
	End

	#rem monkeydoc @hidden
	#end	
	Method BeginRender( bounds:Recti,matrix:AffineMat3f )
	
		Flush()
		
		_rmatrixStack.Push( _rmatrix )
		_rboundsStack.Push( _rbounds )
		
		_rmatrix*=matrix
		_rbounds&=TransformRecti( bounds,_rmatrix )

		Viewport=bounds
		Scissor=New Recti( 0,0,bounds.Size )
		AmbientLight=Color.Black
		BlendMode=BlendMode.Alpha
		PointSize=0
		LineWidth=0
		LineSmoothing=False

		'jl changed
'		TextureFilteringEnabled=True
		TextureFilteringEnabled = _textureFilter2

		OutlineMode=OutlineMode.None
		OutlineColor=Color.Yellow
		OutlineWidth=0
		
		ClearMatrix()
	End
	
	#rem monkeydoc @hidden
	#end	
	Method EndRender()
	
		If _lighting EndLighting()
		
		Flush()
		
		_rbounds=_rboundsStack.Pop()
		_rmatrix=_rmatrixStack.Pop()
	End
	
	#rem monkeydoc The current render target.
	#end	
	Property RenderTarget:RenderTarget()
	
		Return _rtarget
	End
	
	#rem monkeydoc The current viewport.
	
	The viewport describes the rect within the render target that rendering occurs in.
	
	All rendering is relative to the top-left of the viewport, and is clipped to the intersection of the viewport and scissor rects.
	
	This property must not be modified if the canvas is in lighting mode.
		
	#end
	Property Viewport:Recti()
	
		Return _viewport
	
	Setter( viewport:Recti )
		DebugAssert( Not _lighting,"Canvas.Viewport property cannot be modified while lighting" )
		If _lighting return

		Flush()
			
		_viewport=viewport
		
		_dirty|=Dirty.Viewport|Dirty.Scissor
	End

	#rem monkeydoc The current scissor rect.
	
	The scissor rect is a rect within the viewport that can be used for additional clipping.
	
	Scissor rect coordinates are relative to the current viewport rect, but are not affected by the current drawing matrix.
	
	This property must not be modified if the canvas is in lighting mode.
		
	#end
	Property Scissor:Recti()
	
		Return _scissor
	
	Setter( scissor:Recti )
		DebugAssert( Not _lighting,"Canvas.Scissor property cannot be modified while lighting" )
		If _lighting return
	
		Flush()
	
		_scissor=scissor
		
		_dirty|=Dirty.Scissor
	End
	
	#rem monkeydoc Ambient light color for lighting mode.
	
	Sets the ambient light color for lighting.
	
	This property cannot be modified if the canvas is already in lighting mode.
		
	#end
	Property AmbientLight:Color()
	
		Return _ambientLight
	
	Setter( ambient:Color )
		DebugAssert( Not _lighting,"Canvas.AmbientLight property cannot be modified while lighting" )
		If _lighting return
	
		_ambientLight=ambient
	End
	
	#rem monkeydoc The current drawing blend mode.
	#end	
	Property BlendMode:BlendMode()
	
		Return _blendMode
	
	Setter( blendMode:BlendMode )
	
		_blendMode=blendMode
	End
	
	#rem monkeydoc TODO! Texture filtering enabled state.
	
	Set to true for normal behavior.
	
	Set to false for a groovy retro effect.
	
	#end	
	Property TextureFilteringEnabled:Bool()
		
		Return Not _device.RetroMode
		
	Setter( enabled:Bool )
		DebugAssert( Not _lighting,"Canvas.TextureFilteringEnabled property cannot be modified while lighting" )
		If _lighting Return
		
		Local rmode:=Not enabled
		
		If rmode=_device.RetroMode Return
		
		Flush()

		_device.RetroMode=rmode
	End

'------------------------------------------------------------
'jl added
	field _textureFilter2:bool = true
	Property TextureFiltering:Bool()
		Return _textureFilter2
	Setter( enabled:Bool )
		_textureFilter2 = enabled
	End

'------------------------------------------------------------
	
	#rem monkeydoc The current point size for use with DrawPoint.
	#end
	Property PointSize:Float()
	
		Return _pointSize
	
	Setter( pointSize:Float )
	
		_pointSize=pointSize
	End

	#rem monkeydoc The current line width for use with DrawLine.
	#end	
	Property LineWidth:Float()

		Return _lineWidth
	
	Setter( lineWidth:Float )
	
		_lineWidth=lineWidth
	End
	
	#rem monkeydoc Smoothing enabled for DrawLine.
	#end	
	Property LineSmoothing:Bool()
	
		Return _lineSmoothing
	
	Setter( smoothing:Bool )
	
		_lineSmoothing=smoothing
	End
	
	#rem monkeydoc The current font for use with DrawText.
	
	Set font to null to use the default mojo font.
	
	#end	
	Property Font:Font()
	
		Return _font
	
	Setter( font:Font )
	
		If Not font font=_defaultFont
	
		_font=font
	End
	
	#rem monkeydoc The current drawing alpha level.
	
	Note that [[Alpha]] and the alpha component of [[Color]] are multiplied together to produce the final alpha value for rendering. 
	
	This allows you to use [[Alpha]] as a 'master' alpha level.

	#end	
	Property Alpha:Float()
	
		Return _alpha
		
	Setter( alpha:Float )
	
		_alpha=alpha
		
		Local a:=_color.a * _alpha * 255.0
		_pmcolor=UInt(a) Shl 24 | UInt(_color.b*a) Shl 16 | UInt(_color.g*a) Shl 8 | UInt(_color.r*a)
	End
	
	#rem monkeydoc The current drawing color.
	
	Note that [[Alpha]] and the alpha component of [[Color]] are multiplied together to produce the final alpha value for rendering. 
	
	This allows you to use [[Alpha]] as a 'master' alpha level.

	#end
	Property Color:Color()
	
		Return _color
	
	Setter( color:Color )
	
		_color=color
		
		Local a:=_color.a * _alpha * 255.0
		_pmcolor=UInt(a) Shl 24 | UInt(_color.b*a) Shl 16 | UInt(_color.g*a) Shl 8 | UInt(_color.r*a)
	End
	
	#rem monkeydoc The current drawing matrix.
	
	All coordinates passed to draw methods are multiplied by this matrix for rendering.
	
	#end
	Property Matrix:AffineMat3f()
	
		Return _matrix
	
	Setter( matrix:AffineMat3f )
	
		_matrix=matrix
		
		_tanvec=_matrix.i.Normalize()
	End
	
	#rem monkeydoc The current outline mode.
	
	Outline modes control the style of outlines drawn.
	
	See the [[OutlineMode]] enum for a list of possible values.
	
	#end
	Property OutlineMode:OutlineMode()
		
		Return _outlineMode
	
	Setter( mode:OutlineMode )
		
		_outlineMode=mode
	End
	
	#rem monkeydoc The current outline color.
	
	#end
	Property OutlineColor:Color()
		
		Return _outlineColor
		
	Setter( color:Color )
		
		_outlineColor=color

		Local a:=_outlineColor.a * 255.0
		
		_outlinepmcolor=UInt(a) Shl 24 | UInt(_outlineColor.b*a) Shl 16 | UInt(_outlineColor.g*a) Shl 8 | UInt(_outlineColor.r*a)
	End
	
	#rem monkeydoc The current outline width.
	
	#end
	Property OutlineWidth:Float()
		
		Return _outlineWidth
		
	Setter( width:Float )
		
		_outlineWidth=width
	End
	
	#rem monkeydoc Pushes the drawing matrix onto the internal matrix stack.
	
	#end
	Method PushMatrix()
	
		_matrixStack.Push( _matrix )
	End
	
	#rem monkeydoc Pops the drawing matrix off the internal matrix stack.
	
	#end
	Method PopMatrix()
	
		_matrix=_matrixStack.Pop()
	End
	
	#rem monkeydoc Clears the internal matrix stack and sets the drawing matrix to the identitity matrix.
	#end
	Method ClearMatrix()
	
		_matrixStack.Clear()
		_matrix=New AffineMat3f
	End
	
	#rem monkeydoc Translates the drawing matrix.
	
	Translates the drawing matrix. This has the effect of translating all drawing coordinates by `tx` and `ty`.
	
	@param tx X translation.
	
	@param ty Y translation.
	
	@param tv X/Y translation.
	
	#end
	Method Translate( tx:Float,ty:Float )
	
		Matrix=Matrix.Translate( tx,ty )
	End
	
	Method Translate( tv:Vec2f )
	
		Matrix=Matrix.Translate( tv )
	End

	#rem monkeydoc Rotates the drawing matrix.
	
	Rotates the drawing matrix. This has the effect of rotating all drawing coordinates by the angle `rz'.
	
	@param rz Rotation angle in radians.
	
	#end
	Method Rotate( rz:Float )
	
		Matrix=Matrix.Rotate( rz )
	End

	#rem monkeydoc Scales the drawing matrix.
	
	Scales the drawing matrix. This has the effect of scaling all drawing coordinates by `sx` and `sy`.
	
	@param sx X scale factor.
	
	@param sy Y scale factor.
	
	@param sv X/Y scale factor.
	
	#end
	Method Scale( sx:Float,sy:Float )
	
		Matrix=Matrix.Scale( sx,sy )
	End
	
	Method Scale( sv:Vec2f )
	
		Matrix=Matrix.Scale( sv )
	End
	
	#rem monkeydoc Draws a point.
	
	Draws a point in the current [[Color]] using the current [[BlendMode]].
	
	The point coordinates are transformed by the current [[Matrix]] and clipped to the current [[Viewport]] and [[Scissor]].
	
	@param x Point x coordinate.
	
	@param y Point y coordinate.
	
	@param v Point coordinates.
	
	#end
	Method DrawPoint( x:Float,y:Float )
	
		If _pointSize<=0
			AddDrawOp( _shader,_material,_blendMode,1,1 )
			AddPointVertex( x,y,0,0 )
			Return
		Endif
		
		Local d:=_pointSize/2
		AddDrawOp( _shader,_material,_blendMode,4,1 )
		AddVertex( x-d,y-d,0,0 )
		AddVertex( x+d,y-d,1,0 )
		AddVertex( x+d,y+d,1,1 )
		AddVertex( x-d,y+d,0,1 )
	End
	
	Method DrawPoint( v:Vec2f )
		DrawPoint( v.x,v.y )
	End
	
	Private

	Method DrawOutlineLine( x0:Float,y0:Float,x1:Float,y1:Float )
		
'		x0+=.5;y0+=.5;x1+=.5;y1+=.5
		
		Local blendMode:=_outlineMode=OutlineMode.Smooth ? BlendMode.Alpha Else BlendMode.Opaque
		
		Local pmcolor:=_pmcolor
		
		_pmcolor=_outlinepmcolor
		
		If _outlineWidth<=0
			AddDrawOp( _shader,_material,blendMode,2,1 )
			AddPointVertex( x0,y0,0,0 )
			AddPointVertex( x1,y1,1,1 )
			_pmcolor=pmcolor
			Return
		Endif
		
		Local dx:=y0-y1,dy:=x1-x0
		Local sc:=0.5/Sqrt( dx*dx+dy*dy )*_outlineWidth
		dx*=sc;dy*=sc
		
		If _outlineMode=OutlineMode.Solid
			AddDrawOp( _shader,_material,_blendMode,4,1 )
'			AddPointVertex( x0-dx-dy,y0-dy+dx,0,0 )
'			AddPointVertex( x0+dx-dy,y0+dy+dx,0,0 )
'			AddPointVertex( x1+dx+dy,y1+dy-dx,0,0 )
'			AddPointVertex( x1-dx+dy,y1-dy-dx,0,0 )
			AddPointVertex( x0-dx,y0-dy,0,0 )
			AddPointVertex( x0+dx,y0+dy,0,0 )
			AddPointVertex( x1+dx,y1+dy,0,0 )
			AddPointVertex( x1-dx,y1-dy,0,0 )
			_pmcolor=pmcolor
			Return
		End
		
		AddDrawOp( _shader,_material,blendMode,4,2 )

		AddPointVertex( x0,y0,0,0 )
		AddPointVertex( x1,y1,0,0 )
		_pmcolor=0
		AddPointVertex( x1-dx,y1-dy,0,0 )
		AddPointVertex( x0-dx,y0-dy,0,0 )

		AddPointVertex( x0+dx,y0+dy,0,0 )
		AddPointVertex( x1+dx,y1+dy,0,0 )
		_pmcolor=_outlinepmcolor
		AddPointVertex( x1,y1,0,0 )
		AddPointVertex( x0,y0,0,0 )
		
		_pmcolor=pmcolor
	End
	
	Method DrawOutlineLine( v0:Vec2f,v1:Vec2f )
		
		DrawOutlineLine( v0.x,v0.y,v1.x,v1.y )
	End
	
	Method DrawOutline( rect:Rectf )
		
		DrawOutlineLine( rect.min.x,rect.min.y,rect.max.x,rect.min.y )
		DrawOutlineLine( rect.max.x,rect.min.y,rect.max.x,rect.max.y )
		DrawOutlineLine( rect.max.x,rect.max.y,rect.min.x,rect.max.y )
		DrawOutlineLine( rect.min.x,rect.max.y,rect.min.x,rect.min.y )
	End
	
	Public
	
	#rem monkeydoc Draws a line.

	Draws a line in the current [[Color]] using the current [[BlendMode]].
	
	The line coordinates are transformed by the current [[Matrix]] and clipped to the current [[Viewport]] and [[Scissor]].
	
	@param x0 X coordinate of first endpoint of the line.
	
	@param y0 Y coordinate of first endpoint of the line.
	
	@param x1 X coordinate of first endpoint of the line.
	
	@param y1 Y coordinate of first endpoint of the line.
	
	@param v0 First endpoint of the line.
	
	@param v1 Second endpoint of the line.
	
	#end
	Method DrawLine( x0:Float,y0:Float,x1:Float,y1:Float )

		If _lineWidth<=0
			AddDrawOp( _shader,_material,_blendMode,2,1 )
			AddPointVertex( x0,y0,0,0 )
			AddPointVertex( x1,y1,1,1 )
			Return
		Endif
		
'		x0+=.5;y0+=.5;x1+=.5;y1+=.5
		
		Local dx:=y0-y1,dy:=x1-x0
		Local sc:=0.5/Sqrt( dx*dx+dy*dy )*_lineWidth
		dx*=sc;dy*=sc
		
		If Not _lineSmoothing
			AddDrawOp( _shader,_material,_blendMode,4,1 )
			AddPointVertex( x0-dx,y0-dy,0,0 )
			AddPointVertex( x0+dx,y0+dy,0,0 )
			AddPointVertex( x1+dx,y1+dy,0,0 )
			AddPointVertex( x1-dx,y1-dy,0,0 )
			Return
		End
		
		Local pmcolor:=_pmcolor
		
		AddDrawOp( _shader,_material,_blendMode,4,2 )

		AddPointVertex( x0,y0,0,0 )
		AddPointVertex( x1,y1,0,0 )
		_pmcolor=0
		AddPointVertex( x1-dx,y1-dy,0,0 )
		AddPointVertex( x0-dx,y0-dy,0,0 )

		AddPointVertex( x0+dx,y0+dy,0,0 )
		AddPointVertex( x1+dx,y1+dy,0,0 )
		_pmcolor=pmcolor
		AddPointVertex( x1,y1,0,0 )
		AddPointVertex( x0,y0,0,0 )
	End
	
	Method DrawLine( v0:Vec2f,v1:Vec2f )
		
		DrawLine( v0.x,v0.y,v1.x,v1.y )
	End
	
	#rem monkeydoc Draws a triangle.

	Draws a triangle in the current [[Color]] using the current [[BlendMode]].
	
	The triangle vertex coordinates are also transform by the current [[Matrix]].

	#End
	Method DrawTriangle( x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float )
		
		AddDrawOp( _shader,_material,_blendMode,3,1 )
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,1,0 )
		AddVertex( x2,y2,1,1 )
		
		If _outlineMode=OutlineMode.None Return
		
		DrawOutlineLine( x0,y0,x1,y1 )
		DrawOutlineLine( x1,y1,x2,y2 )
		DrawOutlineLine( x2,y2,x0,y0 )
				
	End
	
	Method DrawTriangle( v0:Vec2f,v1:Vec2f,v2:Vec2f )
		
		DrawTriangle( v0.x,v0.y,v1.x,v1.y,v2.x,v2.y )
	End

	#rem monkeydoc Draws a quad.

	Draws a quad in the current [[Color]] using the current [[BlendMode]].
	
	The quad vertex coordinates are also transform by the current [[Matrix]].

	#end
	Method DrawQuad( x0:Float,y0:Float,x1:Float,y1:Float,x2:Float,y2:Float,x3:Float,y3:Float )
		
		AddDrawOp( _shader,_material,_blendMode,4,1 )
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y1,1,0 )
		AddVertex( x2,y2,1,1 )
		AddVertex( x3,y3,0,1 )
		
		If _outlineMode=OutlineMode.None Return
		
		DrawOutlineLine( x0,y0,x1,y1 )
		DrawOutlineLine( x1,y1,x2,y2 )
		DrawOutlineLine( x2,y2,x3,y3 )
		DrawOutlineLine( x3,y3,x0,y0 )
	End

	Method DrawQuad( v0:Vec2f,v1:Vec2f,v2:Vec2f,v3:Vec2f )
		
		DrawQuad( v0.x,v0.y,v1.x,v1.y,v2.x,v2.y,v3.x,v3.y )
	End

	#rem monkeydoc Draws a rectangle.

	Draws a rectangle in the current [[Color]] using the current [[BlendMode]].
	
	The rectangle vertex coordinates are also transform by the current [[Matrix]].

	#end
	Method DrawRect( x:Float,y:Float,w:Float,h:Float )
		
		DrawQuad( x,y,x+w,y,x+w,y+h,x,y+h )
	
		#rem
		Local x0:=x,y0:=y,x1:=x+w,y1:=y+h
		
		AddDrawOp( _shader,_material,_blendMode,4,1 )
		
		AddVertex( x0,y0,0,0 )
		AddVertex( x1,y0,1,0 )
		AddVertex( x1,y1,1,1 )
		AddVertex( x0,y1,0,1 )
		#end
	End
	
	Method DrawRect( rect:Rectf )
		
		DrawRect( rect.X,rect.Y,rect.Width,rect.Height )
	End
	
	Method DrawRect( rect:Rectf,srcImage:Image )
		
		Local tc:=srcImage.TexCoords
		AddDrawOp( srcImage.Shader,srcImage.Material,srcImage.BlendMode,4,1 )
		
		AddVertex( rect.min.x,rect.min.y,tc.min.x,tc.min.y )
		AddVertex( rect.max.x,rect.min.y,tc.max.x,tc.min.y )
		AddVertex( rect.max.x,rect.max.y,tc.max.x,tc.max.y )
		AddVertex( rect.min.x,rect.max.y,tc.min.x,tc.max.y )

		If _outlineMode=OutlineMode.None Return
		
		DrawOutline( rect )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image )
		
		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage )
	End
	
	Method DrawRect( rect:Rectf,srcImage:Image,srcRect:Recti )
		
		Local s0:=Float(srcImage.Rect.min.x+srcRect.min.x)/srcImage.Texture.Width
		Local t0:=Float(srcImage.Rect.min.y+srcRect.min.y)/srcImage.Texture.Height
		Local s1:=Float(srcImage.Rect.min.x+srcRect.max.x)/srcImage.Texture.Width
		Local t1:=Float(srcImage.Rect.min.y+srcRect.max.y)/srcImage.Texture.Height
		
		AddDrawOp( srcImage.Shader,srcImage.Material,srcImage.BlendMode,4,1 )
		
		AddVertex( rect.min.x,rect.min.y,s0,t0 )
		AddVertex( rect.max.x,rect.min.y,s1,t0 )
		AddVertex( rect.max.x,rect.max.y,s1,t1 )
		AddVertex( rect.min.x,rect.max.y,s0,t1 )

		If _outlineMode=OutlineMode.None Return
		
		DrawOutline( rect )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image,srcX:Int,srcY:Int )

		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage,New Recti( srcX,srcY,srcX+width,srcY+height ) )
	End
	
	Method DrawRect( x:Float,y:Float,width:Float,height:Float,srcImage:Image,srcX:Int,srcY:Int,srcWidth:Int,srcHeight:Int )

		DrawRect( New Rectf( x,y,x+width,y+height ),srcImage,New Recti( srcX,srcY,srcX+srcWidth,srcY+srcHeight ) )
	End
	
	#rem monkeydoc Draws an oval.

	Draws an oval in the current [[Color]] using the current [[BlendMode]].
	
	The oval vertex coordinates are also transform by the current [[Matrix]].

	@param x Top left x coordinate for the oval.

	@param y Top left y coordinate for the oval.

	@param width Width of the oval.

	@param height Height of the oval.

	#end
	Method DrawOval( x:Float,y:Float,width:Float,height:Float )
	
		Local xr:=width/2,yr:=height/2
		
		Local dx_x:=xr*_matrix.i.x
		Local dx_y:=xr*_matrix.i.y
		Local dy_x:=yr*_matrix.j.x
		Local dy_y:=yr*_matrix.j.y
		Local dx:=Sqrt( dx_x*dx_x+dx_y*dx_y )
		Local dy:=Sqrt( dy_x*dy_x+dy_y*dy_y )

		Local n:=Max( Int( dx+dy ),12 ) & ~3
		
		Local x0:=x+xr,y0:=y+yr
		
		AddDrawOp( _shader,_material,_blendMode,n,1 )
		
		For Local i:=0 Until n
			Local th:=(i+.5)*Pi*2/n
			Local px:=x0+Cos( th ) * xr
			Local py:=y0+Sin( th ) * yr
			AddPointVertex( px,py,0,0 )
		Next
		
		If _outlineMode=OutlineMode.None Return
		
		For Local i:=0 until n

			Local th0:=(i+.5)*TwoPi/n
			Local px0:=x0+Cos( th0 ) * xr
			Local py0:=y0+Sin( th0 ) * yr
			
			Local th1:=(i+1.5)*TwoPi/n
			Local px1:=x0+Cos( th1 ) * xr
			Local py1:=y0+Sin( th1 ) * yr
			
			DrawOutlineLine( px0,py0,px1,py1 )
		
		Next
		
	End
	
	#rem monkeydoc Draws an ellipse.

	Draws an ellipse in the current [[Color]] using the current [[BlendMode]].
	
	The ellipse is also transformed by the current [[Matrix]].

	@param x Center x coordinate for the ellipse.

	@param y Center y coordinate for the ellipse.

	@param xRadius X axis radius for the ellipse.

	@param yRadius Y axis radius for the ellipse.

	#end
	Method DrawEllipse( x:Float,y:Float,xRadius:Float,yRadius:Float )
		
		DrawOval( x-xRadius,y-yRadius,xRadius*2,yRadius*2 )
	End
	
	#rem monkeydoc Draws a circle.

	Draws a circle in the current [[Color]] using the current [[BlendMode]] and transformed by the current [[Matrix]].

	@param x Center x coordinate for the circle.

	@param y Center y coordinate for the circle.

	@param radius The circle radius.

	#end
	Method DrawCircle( x:Float,y:Float,radius:Float )
		
		DrawOval( x-radius,y-radius,radius*2,radius*2 )
	End

	#rem monkeydoc Draws a polygon.

	Draws a polygon using the current [[Color]], [[BlendMode]] and [[Matrix]].
	
	The `vertices` array must be at least 2 elements long

	@param vertices Array of x/y vertex coordinate pairs.

	#end
	Method DrawPoly( vertices:Float[] )
		
		Local order:=vertices.Length/2
		DebugAssert( order>=1,"Invalid polygon" )
		
		AddDrawOp( _shader,_material,_blendMode,order,1 )
		
		For Local i:=0 Until order*2 Step 2
			
			AddVertex( vertices[i],vertices[i+1],0,0 )
		Next

		If _outlineMode=OutlineMode.None Or order<3 Return
		
		For Local i:=0 Until order-1
			
			Local k:=i*2
			DrawOutlineLine( vertices[k],vertices[k+1],vertices[k+2],vertices[k+3] )
		Next
		
		Local kn:=(order-1)*2
		DrawOutlineLine( vertices[kn],vertices[kn+1],vertices[0],vertices[1] )
	End
	
	#rem monkeydoc Draws a sequence of polygons.

	Draws a sequence of polygons using the current [[Color]], [[BlendMode]] and [[Matrix]].

	@param order The type of polygon: 3=triangles, 4=quads, >4=n-gons.

	@param count The number of polygons.
	
	@param vertices Array of x/y vertex coordinate pairs.
	
	#end
	Method DrawPolys( order:Int,count:Int,vertices:Float[] )
		
		DebugAssert( order>=1 And count>0 And order*count<=vertices.Length,"Invalid polyon" )

		AddDrawOp( _shader,_material,_blendMode,order,count )
		
		For Local i:=0 Until order*count*2 Step 2
			
			AddVertex( vertices[i],vertices[i+1],0,0 )
		Next
		
		If _outlineMode=OutlineMode.None Or order<3 Return
		
		For Local i:=0 Until count
			
			For Local j:=0 Until order-1
				
				Local k:=(i*order+j)*2
				DrawOutlineLine( vertices[k],vertices[k+1],vertices[k+2],vertices[k+3] )
			Next
			
			Local k0:=i*order*2,kn:=(i*order+order-1)*2
			DrawOutlineLine( vertices[kn],vertices[kn+1],vertices[k0],vertices[k0+1] )
		Next
		
	End
	
	#rem monkeydoc Draws a sequence of primtives.

	Draws a sequence of convex primtives using the current [[Color]], [[BlendMode]] and [[Matrix]].
	
	@param order The type of primitive: 1=points, 2=lines, 3=triangles, 4=quads, >4=n-gons.
	
	@param count The number of primitives to draw.
	
	@param vertices Pointer to the first vertex x,y pair.
	
	@param verticesPitch Number of bytes from one vertex x,y pair to the next. Set to 8 for 'tightly packed' vertices.
	
	@param texCoords Pointer to the first texCoord s,t pair. This can be null.
	
	@param texCoordsPitch Number of bytes from one texCoord s,y to the next. Set to 8 for 'tightly packed' texCoords.
	
	@param colors Pointer to the first RGBA uint color value. This can be null.
	
	@param colorsPitch Number of bytes from one RGBA color to the next. Set to 4 for 'tightly packed' colors.
	
	@param image Source image for rendering. This can be null.
	
	@param indices Pointer to sequence of integer indices for indexed drawing. This can by null for non-indexed drawing.
	
	#end
	Method DrawPrimitives( order:Int,count:Int,vertices:Float Ptr,verticesPitch:Int,texCoords:Float Ptr,texCoordsPitch:Int,colors:UInt Ptr,colorsPitch:Int,image:Image,indices:Int Ptr )
		DebugAssert( order>0 And count>0,"Illegal primitive" )

		If image
			AddDrawOp( image.Shader,image.Material,image.BlendMode,order,count )
		Else
			AddDrawOp( _shader,_material,_blendMode,order,count )
		Endif
		
		Local n:=order*count
		
		If indices
			If texCoords And colors
				For Local i:=0 Until n
					Local j:=indices[i]
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+j*texCoordsPitch )
					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+j*colorsPitch )
					AddVertex( vp[0],vp[1],tp[0],tp[1],cp[0] )
				Next
			Else If texCoords
				For Local i:=0 Until n
					Local j:=indices[i]
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+j*texCoordsPitch )
					AddVertex( vp[0],vp[1],tp[0],tp[1] )
				Next
			Else If colors
				For Local i:=0 Until n
					Local j:=indices[i]
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+j*colorsPitch )
					AddVertex( vp[0],vp[1],0,0,cp[0] )
				Next
			Else
				For Local i:=0 Until n
					Local j:=indices[i]
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+j*verticesPitch )
					AddVertex( vp[0],vp[1],0,0 )
				Next
			Endif
		Else
			If texCoords And colors
				For Local i:=0 Until n
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+i*texCoordsPitch )
					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+i*colorsPitch )
					AddVertex( vp[0],vp[1],tp[0],tp[1],cp[0] )
				Next
			Else If texCoords
				For Local i:=0 Until n
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
					Local tp:=Cast<Float Ptr>( Cast<UByte Ptr>( texCoords )+i*texCoordsPitch )
					AddVertex( vp[0],vp[1],tp[0],tp[1] )
				Next
			Else If colors
				For Local i:=0 Until n
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
					Local cp:=Cast<UInt Ptr>( Cast<UByte Ptr>( colors )+i*colorsPitch )
					AddVertex( vp[0],vp[1],0,0,cp[0] )
				Next
			Else
				For Local i:=0 Until n
					Local vp:=Cast<Float Ptr>( Cast<UByte Ptr>( vertices )+i*verticesPitch )
					AddVertex( vp[0],vp[1],0,0 )
				Next
			Endif
		Endif
	End

'------------------------------------------------------------
	'jl modified
	#rem monkeydoc Draws an image.
	Draws an image using the current [[Color]], [[BlendMode]] and [[Matrix]].
	@param tx X coordinate to draw image at.
	@param ty Y coordinate to draw image at.
	@param tv X/Y coordinates to draw image at.
	@param rz Rotation angle, in radians, for drawing.
	@param sx X axis scale factor for drawing.
	@param sy Y axis scale factor for drawing.
	@param sv X/Y scale factor for drawing.
	#end	
	Method DrawImage( image:Image, tx:Float, ty:Float, shader:Shader = null )
	
		Local vs:=image.Vertices
		Local ts:=image.TexCoords
		
		If shader Then
			AddDrawOp( shader, image.Material, image.BlendMode,4,1 )
		Else
			AddDrawOp( image.Shader, image.Material, image.BlendMode,4,1 )
		End If
		
		AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y )
		AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y )
		AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y )
		AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y )
		
		If _lighting And image.ShadowCaster
			AddShadowCaster( image.ShadowCaster,tx,ty )
		Endif
	End
	
	Method DrawImage( image:Image, tx:Float, ty:Float, rz:Float, shader:Shader = null )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
		DrawImage( image, 0,0, shader )
'		DrawImage( image, 0,0 )
		Matrix=matrix
	End

	Method DrawImage( image:Image, tx:Float, ty:Float, rz:Float, sx:Float, sy:Float, shader:Shader = null )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
		DrawImage( image, 0,0, shader )
'		DrawImage( image, 0,0 )
		Matrix=matrix
	End

	Method DrawImage( image:Image, tv:Vec2f, shader:Shader = null )
		DrawImage( image, tv.x, tv.y, shader )
'		DrawImage( image, tv.x,tv.y )
	End
	
	Method DrawImage( image:Image, tv:Vec2f, rz:Float, shader:Shader = null )
		DrawImage( image, tv.x, tv.y, rz, shader )
'		DrawImage( image, tv.x, tv.y, rz )
	End
	
	Method DrawImage( image:Image, tv:Vec2f, rz:Float, sv:Vec2f, shader:Shader = null )
		DrawImage( image, tv.x, tv.y, rz, sv.x, sv.y, shader )
'		DrawImage( image, tv.x,tv.y,rz, sv.x,sv.y )
	End
'------------------------------------------------------------
#rem
	Method DrawImage( image:Image,tx:Float,ty:Float )
	
		Local vs:=image.Vertices
		Local ts:=image.TexCoords
		
		AddDrawOp( image.Shader,image.Material,image.BlendMode,4,1 )
		
		AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y )
		AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y )
		AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y )
		AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y )
		
		If _lighting And image.ShadowCaster
			AddShadowCaster( image.ShadowCaster,tx,ty )
		Endif
	End
	
	Method DrawImage( image:Image,tx:Float,ty:Float,rz:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
		DrawImage( image,0,0 )
		Matrix=matrix
	End

	Method DrawImage( image:Image,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
		DrawImage( image,0,0 )
		Matrix=matrix
	End

	Method DrawImage( image:Image,tv:Vec2f )
		DrawImage( image,tv.x,tv.y )
	End
	
	Method DrawImage( image:Image,tv:Vec2f,rz:Float )
		DrawImage( image,tv.x,tv.y,rz )
	End
	
	Method DrawImage( image:Image,tv:Vec2f,rz:Float,sv:Vec2f )
		DrawImage( image,tv.x,tv.y,rz,sv.x,sv.y )
	End
#end rem
	
	#rem monkeydoc Draws text.

	Draws text using the current [[Color]], [[BlendMode]] and [[Matrix]].

	@param text The text to draw.

	@param tx X coordinate to draw text at.

	@param ty Y coordinate to draw text at.

	@param handleX X handle for drawing.

	@param handleY Y handle for drawing.

	#end
	Method DrawText( text:String,tx:Float,ty:Float,handleX:Float=0,handleY:Float=0 )
	
		If Not text.Length Return
	
		tx-=_font.TextWidth( text ) * handleX
		ty-=_font.Height * handleY
		
		Local gpage:=_font.GetGlyphPage( text[0] )
		If Not gpage gpage=_font.GetGlyphPage( 0 )

		Local sx:Float,sy:Float
		Local tw:Float,th:Float
		
		Local i0:=0,lastChar:=0
		
		while i0<text.Length
		
			Local i1:=i0+1
			Local page:Image
			
			While i1<text.Length
			
				page=_font.GetGlyphPage( text[i1] )
				If page And page<>gpage Exit
				
				i1+=1
			Wend

			Local image:=gpage
			sx=image.Rect.min.x;sy=image.Rect.min.y
			tw=image.Texture.Width;th=image.Texture.Height
			AddDrawOp( image.Shader,image.Material,image.BlendMode,4,i1-i0 )
			
			For Local i:=i0 Until i1
				
				Local char:=text[i]

				tx+=_font.GetKerning( lastChar,char )	'add kerning before render
			
				Local g:=_font.GetGlyph( char )
			
				Local s0:=Float(g.rect.min.x+sx)/tw
				Local t0:=Float(g.rect.min.y+sy)/th
				Local s1:=Float(g.rect.max.x+sx)/tw
				Local t1:=Float(g.rect.max.y+sy)/th
				
				Local x0:=Round( tx+g.offset.x )
				Local y0:=Round( ty+g.offset.y )
				Local x1:=x0+g.rect.Width
				Local y1:=y0+g.rect.Height
	
				AddVertex( x0,y0,s0,t0 )
				AddVertex( x1,y0,s1,t0 )
				AddVertex( x1,y1,s1,t1 )
				AddVertex( x0,y1,s0,t1 )
				
				tx+=g.advance							'add advance after render

				lastChar=char
			Next
			
			gpage=page
			
			i0=i1
		Wend

	End
	
	#rem monkeydoc Adds a light to the canvas.
	
	This method must only be called while the canvas is in lighting mode, ie: between calls to [[BeginLighting]] and [[EndLighting]].
	
	#end
	Method AddLight( light:Image,tx:Float,ty:Float )
		DebugAssert( _lighting,"Canvas.AddLight() can only be used while lighting" )
		If Not _lighting Return
		
		If _lightNV+4>_lightVB.Length Return
		
		Local lx:=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		Local ly:=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		
		Local op:=New LightOp
		op.light=light
		op.lightPos=New Vec2f( lx,ly )
		op.primOffset=_lightNV
		_lightOps.Push( op )

		_vp=_lightVP0+_lightNV
		_lightNV+=4
		
		Local vs:=light.Vertices
		Local ts:=light.TexCoords
		
		AddVertex( vs.min.x+tx,vs.min.y+ty,ts.min.x,ts.min.y,lx,ly,_pmcolor )
		AddVertex( vs.max.x+tx,vs.min.y+ty,ts.max.x,ts.min.y,lx,ly,_pmcolor )
		AddVertex( vs.max.x+tx,vs.max.y+ty,ts.max.x,ts.max.y,lx,ly,_pmcolor )
		AddVertex( vs.min.x+tx,vs.max.y+ty,ts.min.x,ts.max.y,lx,ly,_pmcolor )
	End
	
	Method AddLight( light:Image,tx:Float,ty:Float,rz:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
		AddLight( light,0,0 )
		Matrix=matrix
	End
	
	Method AddLight( light:Image,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
		AddLight( light,0,0 )
		Matrix=matrix
	End
	
	Method AddLight( light:Image,tv:Vec2f )
		AddLight( light,tv.x,tv.y )
	End
	
	Method AddLight( light:Image,tv:Vec2f,rz:Float )
		AddLight( light,tv.x,tv.y,rz )
	End
	
	Method AddLight( light:Image,tv:Vec2f,rz:Float,sv:Vec2f )
		AddLight( light,tv.x,tv.y,rz,sv.x,sv.y )
	End
	
	#rem monkeydoc Adds a shadow caster to the canvas.
	
	This method must only be called while the canvas is in lighting mode, ie: between calls to [[BeginLighting]] and [[EndLighting]].
	
	#end
	Method AddShadowCaster( caster:ShadowCaster,tx:Float,ty:Float )
		DebugAssert( _lighting,"Canvas.AddShadowCaster() can only be used while lighting" )
		If Not _lighting Return
	
		Local op:=New ShadowOp
		op.caster=caster
		op.firstVert=_shadowVerts.Length
		_shadowOps.Push( op )
		
		Local tv:=New Vec2f( tx,ty )
		
		For Local sv:=Eachin caster.Vertices
			sv+=tv
			Local lv:=New Vec2f(
			_matrix.i.x * sv.x + _matrix.j.x * sv.y + _matrix.t.x,
			_matrix.i.y * sv.x + _matrix.j.y * sv.y + _matrix.t.y )
			_shadowVerts.Push( lv )
		Next
	End
	
	Method AddShadowCaster( caster:ShadowCaster,tx:Float,ty:Float,rz:float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz )
		AddShadowCaster( caster,0,0 )
		Matrix=matrix
	End
	
	Method AddShadowCaster( caster:ShadowCaster,tx:Float,ty:Float,rz:Float,sx:Float,sy:Float )
		Local matrix:=Matrix
		Matrix=matrix.Translate( tx,ty ).Rotate( rz ).Scale( sx,sy )
		AddShadowCaster( caster,0,0 )
		Matrix=matrix
	End
	
	Method AddShadowCaster( caster:ShadowCaster,tv:Vec2f )
		AddShadowCaster( caster,tv.x,tv.y )
	End

	Method AddShadowCaster( caster:ShadowCaster,tv:Vec2f,rz:Float )
		AddShadowCaster( caster,tv.x,tv.y,rz )
	End

	Method AddShadowCaster( caster:ShadowCaster,tv:Vec2f,rz:Float,sv:Vec2f )
		AddShadowCaster( caster,tv.x,tv.y,rz,sv.x,sv.y )
	End
	
	#rem monkeydoc Copies a pixmap from the rendertarget.

	This method must not be called while the canvas is in lighting mode.

	@param rect The rect to copy.

	#end
	Method CopyPixmap:Pixmap( rect:Recti )
		DebugAssert( Not _lighting,"Canvas.CopyPixmap() cannot be used while lighting" )
		If _lighting Return Null
		
		Local pixmap:=New Pixmap( rect.Width,rect.Height,PixelFormat.RGBA32 )
		
		CopyPixels( rect,pixmap )
		
		Return pixmap
	End
	
	#rem monkeydoc Copies a rectangular region of pixels to a pixmap.
	#end
	Method CopyPixels( rect:Recti,pixmap:Pixmap,dstx:Int=0,dsty:Int=0 )
		DebugAssert( Not _lighting,"Canvas.CopyPixels() cannot be used while lighting" )
		If _lighting Return

		Flush()
		
		rect=TransformRecti( rect,_rmatrix ) & _rbounds
		
		_device.CopyPixels( rect,pixmap,dstx,dsty )
	End
	
	#rem monkeydoc Gets a pixel color.
	
	Returns the color of the pixel at the given coordinates.
	
	#end
	Method GetPixel:Color( x:Int,y:Int )
		
		Flush()
		
		CopyPixels( New Recti( x,y,x+1,y+1 ),_tmpPixmap1x1 )
		
		Return _tmpPixmap1x1.GetPixel( 0,0 )
	End
	
	#rem monkeydoc Gets a pixel color.
	
	Returns the ARGB color of the pixel at the given coordinates.
	
	#end
	Method GetPixelARGB:UInt( x:Int,y:Int )

		Flush()
		
		CopyPixels( New Recti( x,y,x+1,y+1 ),_tmpPixmap1x1 )
		
		Return _tmpPixmap1x1.GetPixelARGB( 0,0 )
	End
	
	#rem monkeydoc Clears the viewport.
	
	Clears the current viewport to `color`.
	
	This method must not be called while the canvas is in lighting mode.

	@param color Color to clear the viewport to.
	
	#end
	Method Clear( color:Color )
		DebugAssert( Not _lighting,"Canvas.Clear() cannot be used while lighting" )
		If _lighting Return
		
		Validate()
			
		_device.Clear( color )
		
		_drawNV=0
		_drawOps.Clear()
		_drawOp=New DrawOp
	End
	
	#rem monkeydoc Flushes drawing commands.
	
	Flushes any outstanding drawing commands in the draw buffer.
	
	This is only generally necessary if you are drawing to an image.
	
	#end
	Method Flush()
		
		If _drawOps.Empty 
			_device.FlushTarget()
			Return
		Endif
		
		Validate()
		
		_drawVB.Invalidate( 0,_drawNV )
		
		_drawVB.Unlock()
		
		'Render ambient
		'		
		RenderDrawOps( 0 )
		
		If _lighting
		
			'render diffuse gbuffer
			'
			_device.RenderTarget=_gbrtargets[0]
			
			RenderDrawOps( 1 )
			
			'render normal gbuffer
			'
			_device.RenderTarget=_gbrtargets[1]
			
			RenderDrawOps( 2 )

			'back to rendertarget
			'			
			_device.RenderTarget=_rtarget
			
		Endif
		
		_device.FlushTarget()
		
		_drawVP0=Cast<Vertex2f Ptr>( _drawVB.Lock() )
		_drawNV=0
		_drawOps.Clear()
		_drawOp=New DrawOp
	End
	
	#rem monkeydoc True if canvas is in lighting mode.
	#end
	Property IsLighting:Bool()
	
		Return _lighting
	End
	
	#rem monkeydoc Puts the canvas into lighting mode.
	
	While in lighting mode, you can add lights and shadow casters to the cavas using [[AddLight]] and [[AddShadowCaster]]. Lights and shadows
	are later rendered by calling [[EndLighting]].
	
	Each call to BeginLighting must be matched with a corresponding call to EndLighting.
	
	The following properties must not be modified while in lighting mode: [[Viewport]], [[Scissor]], [[AmbientLight]]. Attempting to
	modify these properties while in lighting mode will result in a runtime error in debug builds.
	
	The following methods must not be called in lighting mode: [[Clear]], [[BeginLighting]]. Attepting to call these methods while in
	lighting mode will result in a runtime error in debug builds.
	
	#end
	Method BeginLighting()
		DebugAssert( Not _lighting,"Already lighting" )
		If _lighting Return
		
		_lighting=True
		
		Local gbufferSize:=_device.RenderTargetSize
		gbufferSize.x=Max( gbufferSize.x,1920 )
		gbufferSize.y=Max( gbufferSize.y,1080 )

		If Not _gbuffers[0] Or gbufferSize.x>_gbuffers[0].Width Or gbufferSize.y>_gbuffers[0].Height
			
			For Local i:=0 Until 2
	
				If _gbuffers[i] _gbuffers[i].Discard()
				If _gbrtargets[i] _gbrtargets[i].Discard()
	
				_gbuffers[i]=New Texture( gbufferSize.x,gbufferSize.y,PixelFormat.RGBA32,TextureFlags.Dynamic )
				_gbrtargets[i]=New RenderTarget( New Texture[]( _gbuffers[i] ),Null )
			Next
	
			Local gbufferScale:=New Vec2f( 1 )/Cast<Vec2f>( gbufferSize )
	
			_uniforms.SetVec2f( "GBufferScale",gbufferScale )
			_uniforms.SetTexture( "GBuffer0",_gbuffers[0] )
			_uniforms.SetTexture( "GBuffer1",_gbuffers[1] )
	
		Endif
		
		Validate()
		
		_uniforms.SetVec4f( "AmbientLight",_ambientLight )
		
		_device.RenderTarget=_gbrtargets[0]
		_device.Clear( Color.Black )
			
		_device.RenderTarget=_gbrtargets[1]
		_device.Clear( New Color( .5,.5,0 ) )
		
		_device.RenderTarget=_rtarget
	End
	
	#rem monkeydoc Renders lighting and ends lighting mode.
	
	Renders any lights and shadows casters added to the canvas through calls to [[AddLight]] and [[AddShadowCaster]] and ends lighting mode.
	
	Any lights and shadow casters added to the canvas are also removed and must be added again later if you want to render them again.
	
	This method must be called while the canvas is in lighting mode.
	
	#end
	Method EndLighting()
		DebugAssert( _lighting,"Not lighting" )
		If Not _lighting Return
		
		Flush()
		
		_lightVB.Invalidate( 0,_lightNV )
		
		_lightVB.Unlock()
		
		RenderLighting()
	
		_lightVP0=Cast<Vertex2f Ptr>( _lightVB.Lock() )
		_lightNV=0
		_lightOps.Clear()
		
		_shadowOps.Clear()
		_shadowVerts.Clear()
	
		_lighting=False
	End
	
	'***** INTERNAL *****
	
	#rem monkeydoc @hidden
	#end	
	Property GraphicsDevice:GraphicsDevice()
		
		If _lighting Return Null
		
		Flush()
	
		Return _device
	End

	#rem monkeydoc @hidden
	#end
	Property RenderMatrix:AffineMat3f()
		
		Return _rmatrix
	End
	
	#rem monkeydoc @hidden
	#end
	Property RenderBounds:Recti()
		
		Return _rbounds
	End
	
	Private
	
	Enum Dirty
		GBuffer=1
		Viewport=2
		Scissor=4
	End
	
	Class DrawOp
		Field shader:Shader
		Field material:UniformBlock
		Field blendMode:BlendMode
		Field primOrder:Int
		Field primCount:Int
		Field primOffset:Int
	End
	
	Class LightOp
		Field light:Image
		Field lightPos:Vec2f
		Field primOrder:Int
		Field primOffset:Int
	End
	
	Class ShadowOp
		Field caster:ShadowCaster
		Field firstVert:Int
	End
	
	Global _tmpPixmap1x1:Pixmap
	
	Global _quadIndices:IndexBuffer
	Global _shadowVB:VertexBuffer
	Global _defaultFont:Font

	Global _lighting:Bool=False
	Global _gbuffers:=New Texture[2]
	Global _gbrtargets:=New RenderTarget[2]

	'jl added
'------------------------------------------------------------	
	Field _userUniformCallback:Void(canvas:Canvas, uniform:UniformBlock)
	Field _pmcolor2:UInt=~0
	Field _color2:Color
	Field _xyzPosition:Vec3f = new Vec3f()
'------------------------------------------------------------

	Field _rtarget:RenderTarget
	Field _device:GraphicsDevice
	Field _uniforms:UniformBlock
	
	Field _shader:Shader
	Field _material:UniformBlock
	
	Field _viewport:Recti
	Field _scissor:Recti
	Field _ambientLight:Color
	
	Field _retroMode:Bool
	Field _blendMode:BlendMode
	Field _font:Font
	Field _alpha:Float
	Field _color:Color
	Field _pmcolor:UInt=~0
	Field _pointSize:Float=1
	Field _lineWidth:Float=1
	Field _lineSmoothing:Bool
	Field _matrix:=New AffineMat3f
	Field _tanvec:Vec2f=New Vec2f( 1,0 )
	Field _matrixStack:=New Stack<AffineMat3f>

	Field _outlineMode:OutlineMode
	Field _outlineColor:Color
	Field _outlinepmcolor:UInt
	Field _outlineSmoothing:Bool
	Field _outlineWidth:Float
	
	Field _rmatrix:=New AffineMat3f
	Field _rbounds:=New Recti( 0,0,$40000000,$40000000 )
	Field _rmatrixStack:=New Stack<AffineMat3f>
	Field _rboundsStack:=New Stack<Recti>
	
	Field _dirty:Dirty
	Field _projMatrix:Mat4f
	Field _rviewport:Recti
	Field _rviewportClip:Vec2i
	Field _rscissor:Recti
	
	Field _vp:Vertex2f Ptr

	Field _drawVB:VertexBuffer
	Field _drawVP0:Vertex2f Ptr
	Field _drawNV:Int
	Field _drawOps:=New Stack<DrawOp>
	Field _drawOp:=New DrawOp

	Field _lightVB:VertexBuffer
	Field _lightVP0:Vertex2f Ptr
	Field _lightNV:Int
	Field _lightOps:=New Stack<LightOp>
	
	Field _shadowOps:=New Stack<ShadowOp>
	Field _shadowVerts:=New Stack<Vec2f>
	
	Const MaxVertices:=65536
	Const MaxShadowVertices:=16384
	Const MaxLights:=1024
	
	Function Init2()
		Global inited:=False
		If inited Return
		inited=True
		
		_tmpPixmap1x1=New Pixmap( 1,1,PixelFormat.RGBA8 )

		Local nquads:=MaxVertices/4
		
		_quadIndices=New IndexBuffer( IndexFormat.UINT16,nquads*6 )
		
		Local ip:=Cast<UShort Ptr>( _quadIndices.Lock() )
		
		For Local i:=0 Until nquads*4 Step 4
			ip[0]=i
			ip[1]=i+1
			ip[2]=i+2
			ip[3]=i
			ip[4]=i+2
			ip[5]=i+3
			ip+=6
		Next

		_quadIndices.Invalidate( 0,nquads*6 )
		
		_quadIndices.Unlock()
		
		_shadowVB=New VertexBuffer( Vertex2f.Format,MaxShadowVertices )

		_defaultFont=mojo.graphics.Font.Load( "font::DejaVuSans.ttf",16 )
	End
	
	Method Init( rtarget:RenderTarget,device:GraphicsDevice )
		Init2()
		
		_rtarget=rtarget
		_device=device

		_device.RenderTarget=_rtarget
		
		_device.CullMode=CullMode.None
		_device.DepthFunc=DepthFunc.Always
		_device.DepthMask=False
		
		_uniforms=New UniformBlock( 1 )
		_device.BindUniformBlock( _uniforms )

		_drawVB=New VertexBuffer( Vertex2f.Format,MaxVertices )
		_drawVP0=Cast<Vertex2f Ptr>( _drawVB.Lock() )
		_drawNV=0
		
		_lightVB=New VertexBuffer( Vertex2f.Format,MaxLights*4 )
		_lightVP0=Cast<Vertex2f Ptr>( _lightVB.Lock() )
		_lightNV=0
		
'		_shadowVB=New VertexBuffer( Vertex2f.Format,65536 )
		
		_device.IndexBuffer=_quadIndices

		_shader=Shader.GetShader( "null" )
		_material=New UniformBlock( 2 )
		
		_viewport=New Recti( 0,0,640,480 )
		_ambientLight=Color.Black
		_blendMode=BlendMode.Alpha
		
		_font=_defaultFont
		
		_alpha=1
		_color=Color.White
		_pmcolor=$ffffffff
		
		_outlineMode=OutlineMode.None
		_outlineColor=Color.Yellow
		_outlinepmcolor=$ffffffff
		_outlineWidth=0
		
		'jl added
		_color2=Color.White
		_pmcolor2=$ffffffff

		_matrix=New AffineMat3f
	End

	'Vertices
	'
	#rem
	Method AddVertex( x:Float,y:Float,s0:Float,t0:Float,s1:Float,t1:Float,color:UInt )
		_vp->position.x=x
		_vp->position.y=y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=s1
		_vp->texCoord1.y=t1
		_vp->color=color
		_vp+=1
	End
	#end

	Method AddVertex( tx:Float,ty:Float,s0:Float,t0:Float,s1:Float,t1:Float,color:UInt )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=s1
		_vp->texCoord1.y=t1
		_vp->color=color

		'jladded
'------------------------------------------------------------		
		_vp->color2 = _pmcolor2
		_vp->xyzPosition = _xyzPosition
'------------------------------------------------------------
		_vp+=1
	End

	Method AddVertex( tx:Float,ty:Float,s0:Float,t0:Float,color:UInt )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=_tanvec.x
		_vp->texCoord1.y=_tanvec.y
		_vp->color=color

		'jladded
'------------------------------------------------------------		
		_vp->color2 = _pmcolor2
		_vp->xyzPosition = _xyzPosition
'------------------------------------------------------------

		_vp+=1
	End

'jl added
'------------------------------------------------------------
	Method AddVertex( tx:Float,ty:Float, s0:Float,t0:Float, color:UInt, xp:float, yp:float, zp:float )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=_tanvec.x
		_vp->texCoord1.y=_tanvec.y
		_vp->color=color
		'jladded
		_vp->color2 = _pmcolor2
		_vp->xyzPosition.x = xp
		_vp->xyzPosition.y = yp
		_vp->xyzPosition.z = zp
		_vp+=1
	End

	Method AddVertexNormal( tx:Float,ty:Float,s0:Float,t0:Float, color:UInt, xp:float, yp:float, zp:float, nx:float, ny:float, nz:float )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=s0
		_vp->texCoord1.y=t0
		_vp->color=color
		'jladded
		_vp->color2 = _pmcolor2
		_vp->xyzPosition.x = xp
		_vp->xyzPosition.y = yp
		_vp->xyzPosition.z = zp
		_vp->Normal.x = nx
		_vp->Normal.y = ny
		_vp->Normal.z = nz
		_vp+=1
	End

	Method AddVertexNormal2( tx:Float,ty:Float,s0:Float,t0:Float, s1:float, t1:float, color:UInt, xp:float, yp:float, zp:float, nx:float, ny:float, nz:float )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=s1
		_vp->texCoord1.y=t1
		_vp->color=color
		'jladded
		_vp->color2 = _pmcolor2
		_vp->xyzPosition.x = xp
		_vp->xyzPosition.y = yp
		_vp->xyzPosition.z = zp
		_vp->Normal.x = nx
		_vp->Normal.y = ny
		_vp->Normal.z = nz
		_vp+=1
	End
'------------------------------------------------------------
	
	Method AddPointVertex( tx:Float,ty:Float,s0:Float,t0:Float )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x + .5
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y + .5
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->color=_pmcolor

		'jladded
'------------------------------------------------------------		
		_vp->color2 = _pmcolor2
		_vp->xyzPosition = _xyzPosition
'------------------------------------------------------------
		_vp+=1
	End
	
	Method AddVertex( tx:Float,ty:Float,s0:Float,t0:Float )
		_vp->position.x=_matrix.i.x * tx + _matrix.j.x * ty + _matrix.t.x
		_vp->position.y=_matrix.i.y * tx + _matrix.j.y * ty + _matrix.t.y
		_vp->texCoord0.x=s0
		_vp->texCoord0.y=t0
		_vp->texCoord1.x=_tanvec.x
		_vp->texCoord1.y=_tanvec.y
		_vp->color=_pmcolor
		'jladded
'------------------------------------------------------------		
		_vp->color2 = _pmcolor2
		_vp->xyzPosition = _xyzPosition
'------------------------------------------------------------
		_vp+=1
	End
	
	'Drawing
	'	
	Method AddDrawOp( shader:Shader,material:UniformBlock,blendMode:BlendMode,primOrder:int,primCount:Int )

		If _drawNV+primCount*primOrder>_drawVB.Length
			Flush()
		Endif
		
		If blendMode=BlendMode.None blendMode=_blendMode
		
		If shader<>_drawOp.shader Or material<>_drawOp.material Or blendMode<>_drawOp.blendMode Or primOrder<>_drawOp.primOrder
		
			'pad quads so primOffset always on a 4 vert boundary
			If primOrder=4 And _drawNV & 3
				_drawNV+=4-(_drawNV&3)
			Endif
			
			_drawOp=New DrawOp
			_drawOp.shader=shader
			_drawOp.material=material
			_drawOp.blendMode=blendMode
			_drawOp.primOrder=primOrder
			_drawOp.primCount=primCount
			_drawOp.primOffset=_drawNV
			_drawOps.Push( _drawOp )
		Else
			_drawOp.primCount+=primCount
		Endif
		
		_vp=_drawVP0+_drawNV
		_drawNV+=primCount*primOrder
	End
	
	Method Validate()
	
		If _dirty & Dirty.Viewport

			Local tviewport:=TransformRecti( _viewport,_rmatrix )
			
			_rviewport=tviewport & _rbounds
			
			_rviewportClip=tviewport.Origin-_rviewport.Origin
	
			Local rmatrix:=New Mat4f
			rmatrix.i.x=_rmatrix.i.x
			rmatrix.j.y=_rmatrix.j.y
			rmatrix.t.x=_rviewportClip.x
			rmatrix.t.y=_rviewportClip.y
			
			If _rtarget
				_projMatrix=Mat4f.Ortho( 0,_rviewport.Width,0,_rviewport.Height,-1,1 ) * rmatrix
			Else
				_projMatrix=Mat4f.Ortho( 0,_rviewport.Width,_rviewport.Height,0,-1,1 ) * rmatrix
			Endif
			
			_uniforms.SetMat4f( "ModelViewProjectionMatrix",_projMatrix )
			
			_uniforms.SetVec2f( "ViewportOrigin",_rviewport.Origin )
			
			_uniforms.SetVec2f( "ViewportSize",_rviewport.Size )
	
			_uniforms.SetVec2f( "ViewportClip",_rviewportClip )
			
			_device.Viewport=_rviewport
		Endif
		
'------------------------------------------------------------
'jl added
		If Not UserUniforms.Empty
			For Local useruniform:=Eachin UserUniforms
				useruniform.callback(useruniform, _uniforms)
			Next
		End If 
'------------------------------------------------------------

		If _dirty & Dirty.Scissor

			_rscissor=TransformRecti( _scissor+_viewport.Origin,_rmatrix ) & _rviewport
			
			_device.Scissor=_rscissor
		Endif
		
		_dirty=Null
	End
	
	Method RenderDrawOps( rpass:Int )
	
		_device.RenderPass=rpass
		
		_device.VertexBuffer=_drawVB
		
		Local rpassMask:=1 Shl rpass
		
		For Local op:=Eachin _drawOps
		
			Local shader:=op.shader
			If Not (shader.RenderPassMask & rpassMask) Continue
		
			_device.Shader=shader
			_device.BlendMode=op.blendMode
			_device.BindUniformBlock( op.material )

			Select op.primOrder
			Case 4
				_device.RenderIndexed( 3,op.primCount*2,op.primOffset/4*6 )
			Default
				_device.Render( op.primOrder,op.primCount,op.primOffset )
			End

'			_device.Render( op.primOrder,op.primCount,op.primOffset )

		Next
	End
	
	'Shadows
	'
	Method DrawShadows:Int( lightOp:LightOp )
	
		Const EXTRUDE:=1024.0
		
		Local lv:=lightOp.lightPos
		
		Local vp0:=Cast<Vertex2f Ptr>( _shadowVB.Lock() ),n:=0
		
		For Local op:=Eachin _shadowOps
		
			Local vert0:=op.firstVert
			Local nverts:=op.caster.Vertices.Length
			
			Local tv:=_shadowVerts[vert0+nverts-1]
			
			For Local iv:=0 Until nverts
			
				Local pv:=tv
				tv=_shadowVerts[vert0+iv]
				
				Local dv:=tv-pv
				Local nv:=dv.Normal.Normalize()
				Local pd:=-pv.Dot( nv )
				
				Local d:=lv.Dot( nv )+pd
				If d<0 Continue
				
				If n+9>_shadowVB.Length Exit
				Local tp:=vp0+n
				n+=9
			
				Local hv:=(pv+tv)/2
				
				Local pv2:=pv + (pv-lv).Normalize() * EXTRUDE
				Local tv2:=tv + (tv-lv).Normalize() * EXTRUDE
				Local hv2:=hv + (hv-lv).Normalize() * EXTRUDE
				
				tp[0].position=tv;tp[1].position=tv2;tp[2].position=hv2
				tp[3].position=tv;tp[4].position=hv2;tp[5].position=pv
				tp[6].position=hv2;tp[7].position=pv2;tp[8].position=pv
				
			Next
			
		Next
		
		_shadowVB.Invalidate( 0,n )
		
		_shadowVB.Unlock()
		
		Return n
	End
		
	'Lighting
	'
	Method RenderLighting()
	
		_device.BlendMode=BlendMode.Additive
		
		_device.VertexBuffer=_lightVB
		
		For Local op:=Eachin _lightOps
		
			Local n:=DrawShadows( op )
			
			If n
				_device.RenderPass=4
				_device.RenderTarget=_gbrtargets[0]
				_device.BlendMode=BlendMode.Opaque
				_device.ColorMask=ColorMask.Alpha
				_device.VertexBuffer=_shadowVB
				_device.Shader=Shader.GetShader( "shadow" )

				_device.Clear( Color.White )
				_device.Render( 3,n/3,0 )
				
				_device.RenderPass=5
				_device.RenderTarget=_rtarget
				_device.BlendMode=BlendMode.Additive
				_device.ColorMask=ColorMask.All
				_device.VertexBuffer=_lightVB
				
			Else
				_device.RenderPass=4
			Endif
			
			Local light:=op.light
			
			_device.Shader=light.Shader
			_device.BindUniformBlock( light.Material )
			
			_device.Render( 4,1,op.primOffset )
		
		Next
		
	End

End
