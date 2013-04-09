----------------------------------------------------------------------------------
-- Game Analytics wrapper for Corona SDK (www.coronalabs.com)
-- Version 1.0
--
-- The Game Analytics Corona SDK wrapper makes it easy to send event data to 
-- the Game Analytics service for visualization. By collecting data from users 
-- of your app you will be able to identify bugs and balance issues, track 
-- purchases, or determine how your players really use your app!
-- This code for the Game Analytics wrapper is open source - feel free to create 
-- your own fork, or use the code to develop your own wrapper.
--
-- For documentation see: https://beta.gameanalytics.com/docs/
-- Sign up and get your keys here: https://beta.gameanalytics.com/
--
-- Written by Jacob Nielsen for Game Analytics in 2013
----------------------------------------------------------------------------------

GameAnalytics = {}

local json = require "json" 
local crypto = require "crypto"
local lfs = require "lfs"

local api_url		= "http://api.gameanalytics.com"
local api_version	= 1

local game_key, secret_key
local user_id, build, session_id
local endpoint_url

GameAnalytics.isDebug				= true
GameAnalytics.runInSimulator		= false
GameAnalytics.submitWhileRoaming	= false
GameAnalytics.submitSystemInfo		= false
GameAnalytics.archiveEvents			= false
GameAnalytics.archiveEventsLimit	= 512
GameAnalytics.waitForCustomUserID	= false

local customUserID
local disabledInSimulator = false

local categories = { design=true, quality=true, user=true, business=true }
local systemProperties = { "model", "environment", "platformName", "platformVersion", "architectureInfo" }

local isSimulator = "simulator" == system.getInfo("environment")
local platformName = system.getInfo("platformName")
local isRoaming, hasConnection = false, true

local createUserID, createSessionID
local saveEvents, storeEvent, saveData, loadData, onSystemEvent, GAPrint, submitArchivedEvents

local gameAnalyticsID, gameAnalyticsData, dataDirectory
local storedEventsCount = 0
local maxStoredEventsCount = 100
local archiveEventsLimitReached = false
local rand = math.random

----------------------------------------
-- Initialize
----------------------------------------
function GameAnalytics.init ( params )

	if isSimulator and not GameAnalytics.runInSimulator then
		GAPrint ( nil, "disabled" )
		disabledInSimulator = true
	else
		if params then
			game_key	= params["game_key"]
			secret_key	= params["secret_key"]
			build		= params["build_name"]
		end
		
		assert(game_key ~= nil, "GA: You have to supply a game_key when initializing!")
		assert(secret_key ~= nil, "GA: You have to supply a secret_key when initializing!")
		assert(build ~= nil, "GA: You have to supply a build name when initializing!")
		
		if GameAnalytics.waitForCustomUserID and customUserID == nil then
			GAPrint ( nil, "wait" )
		else
			if customUserID then 
				gameAnalyticsID = { user_id = customUserID }
				os.remove ( system.pathForFile( "GameAnalyticsID.txt", system.DocumentsDirectory ) )
			else 
				gameAnalyticsID = loadData( system.pathForFile( "GameAnalyticsID.txt", system.DocumentsDirectory ) ) 
			end
			
			if not gameAnalyticsID["user_id"] then
				gameAnalyticsID["user_id"] = createUserID()
				saveData ( gameAnalyticsID, system.pathForFile( "GameAnalyticsID.txt", system.DocumentsDirectory ) )
			end
			
			user_id = gameAnalyticsID["user_id"]
			
			session_id = createSessionID()
			endpoint_url = api_url.."/"..api_version.."/"..game_key.."/"
			
			if lfs.chdir( system.pathForFile( "", system.DocumentsDirectory ) ) then 
				if not ( lfs.attributes( (lfs.currentdir().."/GameAnalyticsData"):gsub("\\$",""),"mode") == "directory" ) then
					lfs.mkdir( "GameAnalyticsData" )
					dataDirectory = lfs.currentdir().."/GameAnalyticsData"
				else
					dataDirectory = lfs.currentdir().."/GameAnalyticsData"
					if (lfs.attributes ( dataDirectory ).size) > GameAnalytics.archiveEventsLimit*1000 then
						archiveEventsLimitReached = true
					end
				end
			end
			
			GAPrint ( nil, "init" )
			
			local function submitSystemInfo ()
				if GameAnalytics.submitSystemInfo then
				
					local systemInfo = {}
					
					for i=1, #systemProperties do
					
						local systemProperty = {}
						systemProperty["event_id"] = "system:"..systemProperties[i] 
						systemProperty["message"]  = system.getInfo( systemProperties[i] )
						table.insert ( systemInfo, systemProperty )
					end
					GameAnalytics.newEvent ( "systemInfo", unpack (systemInfo) )
				end
			end
			if GameAnalytics.archiveEvents then 
				Runtime:addEventListener( "system", onSystemEvent )
				submitArchivedEvents ( submitSystemInfo ) 
			else submitSystemInfo () end
		end
	end
end

----------------------------------------
-- New event
----------------------------------------
function GameAnalytics.newEvent ( category, ... )
	
	if not disabledInSimulator then
		if user_id then
			local archivedEvents, submittingSystemInfo, waitingForUserID = false, false, false
			
			if category == "systemInfo" then
				submittingSystemInfo = true
				category = "quality"
			end

			if categories[category] then
			
				local params, headers, message = {}, {}, {...}
				
				for k,v in pairs( message ) do
				
					assert(type(v) == "table", "GA: Attempt to submit non-table event!")
					if not v["session_id"] then
						v["build"]		=	build
						v["session_id"]	=	session_id
						if user_id then 
							v["user_id"] = user_id
						else 
							waitingForUserID = true 
						end
					else
						archivedEvents = true
					break end
				end
				
				local json_message = json.encode ( message )
				params.body = json_message
				
				local signature = json_message..secret_key
				headers['Authorization'] = crypto.digest( crypto.md5, signature )
				headers['Content-Type'] = "application/json"
				params.headers = headers
				
				local post_url = endpoint_url..category
				
				local function networkListener( event ) 
					if ( event.isError ) then
						storeEvent (  "no connection", category, message )
					else
						if archivedEvents then GAPrint ( "Submitting archived events: "..category..", response: "..event.response )
						elseif submittingSystemInfo then GAPrint ( "Submitting system info: "..category..", response: "..event.response )
						else GAPrint ( "Event: "..category..", response: "..event.response ) end
					end
				end
			
				if hasConnection then
					if not GameAnalytics.submitWhileRoaming and isRoaming then
						storeEvent (  "roaming", category, message )
					else
						network.request( post_url, "POST", networkListener, params)
					end
				else
					storeEvent ( "no connection", category, message )
				end
			else
				assert ( false, "GA: Category error! '"..category.."' is not a valid category." )
			end
		else
			if GameAnalytics.waitForCustomUserID and not customUserID then
				GAPrint ( "Event discarded. Waiting for custom user id!" )
			else
				assert ( false, "GA: You have to initialize Game Analytics before submitting events!" )
			end
		end
	end
end

----------------------------------------
-- Set custom user id
----------------------------------------
function GameAnalytics.setCustomUserID ( id )

	if not disabledInSimulator then
		if game_key then
			if GameAnalytics.waitForCustomUserID then
				customUserID = id
				user_id = customUserID
				GAPrint ( "Custom user id set. Initializing GameAnalytics now..." )
				GameAnalytics.init ()
			else
				assert ( false, "GA: You are trying to call setCustomUserID. Set waitForCustomUserID to true if you want to use a custom user id!" )
			end
		else
			assert ( false, "GA: You can't set custom user id before Game Analytics is initialized!" )
		end
	end
end

----------------------------------------
-- Archive data
----------------------------------------
saveData = function ( data, path )
	local fh = io.open( path, "w+" )
	local content = json.encode( data )
	fh:write( content )
	io.close( fh )
end

loadData = function ( path )
	local fh = io.open( path, "r" )
	local data
	if fh then
		local content = fh:read( "*a" )
		if content then data = json.decode( content ) 
		io.close( fh )
		else return end
	else data = {} end
	return data
end

----------------------------------------
-- System event
----------------------------------------
onSystemEvent = function ( event )
	if event.type == "applicationExit" then
		saveEvents ()
	end
end

----------------------------------------
-- Archived Events
----------------------------------------
storeEvent = function ( reason, category, event )
	
	if GameAnalytics.archiveEvents then
		if archiveEventsLimitReached then
			GAPrint ( "Event: size limit for archived events reached (event data will be lost)" )
		else
			if not gameAnalyticsData then gameAnalyticsData = {} end
			if not gameAnalyticsData[category] then gameAnalyticsData[category] = {} end
			
			for i=1,#event do table.insert ( gameAnalyticsData[category], event[i] ) end
			GAPrint ( "Archiving event ("..reason.."): category: "..category )
			storedEventsCount = storedEventsCount + 1
			if storedEventsCount >= maxStoredEventsCount then 
				saveEvents ()
				storedEventsCount = 0
			end
		end
	else
		GAPrint ( "Can't submit event ("..reason.."). Data archiving disabled (event data will be lost)" )
	end
end

saveEvents = function ()
	if gameAnalyticsData then
		local time = os.time ()
		local path = system.pathForFile( "/GameAnalyticsData/"..time..".txt", system.DocumentsDirectory )
		saveData ( gameAnalyticsData, path )
		gameAnalyticsData = nil
		GAPrint ( time, "save" )
	end
end

submitArchivedEvents = function ( callback )

	timer.performWithDelay ( 500, function ()
		if hasConnection then
			if not GameAnalytics.submitWhileRoaming and isRoaming then 
				if callback then callback () end
			else
				for file in lfs.dir( dataDirectory ) do
					local data = loadData ( system.pathForFile( "/GameAnalyticsData/"..file, system.DocumentsDirectory ) )
					if data then
						for k,v in pairs( categories ) do 
							if data[k] then
								GameAnalytics.newEvent ( k, unpack (data[k]) ) 
							end
						end
						os.remove ( dataDirectory.."/"..file )
					end
				end
				if callback then callback () end
			end
		else 
			if callback then callback () end 
		end
	end )
end

----------------------------------------
-- User id
----------------------------------------
createUserID = function ()
	if platformName == "Android" then
		return system.getInfo ( "deviceID" )
	else
		local time = os.time ()
		local name, deviceInfo = system.getInfo ("name" ), system.getInfo ( "architectureInfo" )
		local chars = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
		local randomHexTable = {} math.randomseed( time )
		for i=1,16 do randomHexTable[i]=chars[rand(1,16)] end
		local randomHex = table.concat ( randomHexTable )
		local id = time..name..deviceInfo..randomHex
		id = id:gsub("%s+", "")
		return crypto.digest( crypto.md5, id )
	end
end

----------------------------------------
-- Session id
----------------------------------------
createSessionID = function ()
	local time = os.time ()
	return crypto.digest( crypto.md5, user_id..time )
end

----------------------------------------
-- Debug print
----------------------------------------
GAPrint = function ( message, id )

	if GameAnalytics.isDebug then
		if not id then print ( "GA: "..message )
		elseif id == "init" then
			GAPrint ( "" )
			GAPrint ( "=============================================================" )
			if GameAnalytics.customUserID then GAPrint ( "Game Analytics initialized with custom user id." )
			else GAPrint ( "Game Analytics initialized." ) end
			GAPrint ( "-------------------------------------------------------------" )
			if GameAnalytics.customUserID then GAPrint ( "Custom user ID: "..tostring( GameAnalytics.customUserID )) 
			else GAPrint ( "User ID:    "..tostring( user_id )) end
			GAPrint ( "Session ID: "..tostring( session_id ))
			GAPrint ( "-------------------------------------------------------------" )
			GAPrint ( "Submit system info:    "..tostring ( GameAnalytics.submitSystemInfo ) )
			GAPrint ( "Submit while roaming:  "..tostring ( GameAnalytics.submitWhileRoaming ) )
			GAPrint ( "Archive events:        "..tostring ( GameAnalytics.archiveEvents ) )
			if GameAnalytics.archiveEvents then GAPrint ( "Limit archived events: "..tostring ( GameAnalytics.archiveEventsLimit ).." kb" ) end
			GAPrint ( "=============================================================" )
		elseif id == "disabled" then
			GAPrint ( "-------------------------------------------------------------" )
			GAPrint ( "GameAnalytics is disabled in the Corona simulator." )
			GAPrint ( "-------------------------------------------------------------" )
		elseif id == "connection" then
			GAPrint ( "-------------------------------------------------------------" )
			GAPrint ( "Device has connection: "..tostring (hasConnection) )
			GAPrint ( "Device is roaming:     "..tostring(isRoaming) )
			GAPrint ( "-------------------------------------------------------------" )
		elseif id == "wait" then
			GAPrint ( "-------------------------------------------------------------" )
			GAPrint ( "GameAnalytics initialization called. Game Analytics will" )
			GAPrint ( "initialize automatically when custom user id is set!" )
			GAPrint ( "-------------------------------------------------------------" )
		elseif id == "save" then
			GAPrint ( "=============================================================" )
			GAPrint ( "Saving archived events. File id: "..message..".txt" )
			GAPrint ( "=============================================================" )
		end
	end
end
			
----------------------------------------
-- Network reachability
----------------------------------------
local function networkReachabilityListener ( event )
	if not disabledInSimulator then
		hasConnection = event.isReachable
		if event.isReachable then
			isRoaming = event.isReachable == event.isReachableViaCellular
		end
		GAPrint ( nil, "connection" )
	end
end

if network.canDetectNetworkStatusChanges then
	network.setStatusListener( "www.gameanalytics.com", networkReachabilityListener )
else
	GAPrint ( "Network reachability not supported on this platform!" ) 
	GAPrint ( "It is not possible to detect if the device is roaming." ) 
end

