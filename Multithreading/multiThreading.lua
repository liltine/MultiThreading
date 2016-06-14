--MultiThreading API v0.1 by leniel
Thread = {} -- thread class encapsulate a coroutine and handles her eventFilter, accept function with arguments, starts  execution in constructor to pass starting args to coroutine .
function Thread.new(func, ...)
	local tArgs = { ... }
	local self = {}
	local _routine 
	local _filter = nil 
	local _routine = coroutine.create(func)
	
	function self.status() -- expose coroutine status
		return coroutine.status(_routine)
	end
	
	function self.resume(eventData) -- resume corroutine if event correspond or yielded with no filter
		if (_filter == nil) or (_filter == eventData[1]) or eventData[1] == "terminate" then
			local ok, param = coroutine.resume(_routine,unpack(eventData))
			if not ok then
				error( param)
				--pcall( 	function()
				--		term.setCursorBlink( false )
				--		print( "Press any key to continue" )
				--		os.pullEvent( "key" ) 
				--		end 
				--	)
				--os.shutdown()
			else
				_filter=param
			end
		end
	end

	local ok, err = pcall( function() self.resume(tArgs) end)--first start immediatly and pass starting args !
	if not ok then
		--term.setCursorBlink( false )
		print(err)
		print( "Press any key to continue" )
		os.pullEvent( "key" ) 
		--table.insert(_deadThreads,key)
	end
	
	return self
end

ThreadController = {} -- the parent coroutine witch gives turn to the coroutines and handles their death
function ThreadController.new()
	local self = {}
	local _threads = {} --Active threads table
	local _deadThreads={} --Threads to be terminated
	local _eventData={} --last event to pass to all coroutines that might be interested
	
	function self.addThread(func ,...) --append a new coroutine to the execution flow
		table.insert(_threads,Thread.new(func,...))
	end

	function self.runThreading() -- starting the controller ! (must have the main coroutine ready !)
		while true do 
			for key,thread in pairs(_threads) do --pass through all coroutines in the active coroutines tables
				if thread.status() == "dead" then --if it is finished then add it to the trashbin queue
					table.insert(_deadThreads,key)
				else
					local ok, err = pcall( function() thread.resume(_eventData) end)-- else ask if resume is needed (event filter)
					if not ok then
						--term.setCursorBlink( false )
						print(err)
						print( "Press any key to continue" )
						os.pullEvent( "key" ) 
						table.insert(_deadThreads,key)
					else
						if thread.status() == "dead" then -- if it finished then add it to trash queue
							table.insert(_deadThreads,key)
						end
					end
				end
			end
			for _,key in pairs(_deadThreads) do --remove dead corroutines from the table
				table.remove(_threads,key)
			end
			_deadThreads={} --clear the trash queue
			--print("threads : "..#_threads) --debug
			--if #_threads ==0 then -- if no more coroutines to run then finish execution
			--	return true
			--end
			_eventData={os.pullEventRaw()} --wait for next event
		end
	end

	return self
end
_G.TC=ThreadController.new()