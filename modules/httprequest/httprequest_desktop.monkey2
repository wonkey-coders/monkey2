
Namespace httprequest

Function Hello()
End

Class HttpRequest Extends HttpRequestBase
	
	Protected

	Method OnSetHeader( header:String,value:String ) Override
	End
	
	Method OnSend( text:String ) Override
		
		Global id:=0
		
		id+=1
		
		Local tmp:=GetEnv( "TMP" )+"\wget-"+id+".txt"
		
	#if __TARGET__="macos"
	
		Local cmd:="curl -s -m "+timeout+" -o ~q"+tmp+"~q ~q"+url+"~q"
		
	#else
		Local post_data:=_method="POST" ? " -post-data=~q"+text+"~q" Else ""
		Local cmd:="wget -q -T "+_timeout+" -O ~q"+tmp+"~q --method="+_method+post_data+" ~q"+_url+"~q"
	#endif
		
		Local process:=New Process
		
		process.Finished=Lambda()
		
			If process.ExitCode=0
				
				_status=200
				
				_response=LoadString( tmp )
				
				SetReadyState( ReadyState.Done )
				
			Else
				
				_status=404
				
				SetReadyState( ReadyState.Error )
				
			Endif
			
			DeleteFile( tmp )
		End
		
		SetReadyState( ReadyState.Loading )
		
		process.Start( cmd )
		
	End
End
