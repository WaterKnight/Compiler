require 'waterlua'

local params = {...}

addToEnv(unpack(params))

print(unpack(params))

addLine([[
struct Loading
	static integer LOADING_PARTS_AMOUNT = 0
]])

local f = io.open(logsDir..[[loadingParts.txt]], 'w+')

for i = 1, #loadingParts, 1 do
	local part = loadingParts[i]

	local name = part.name

	addLine([[
		static trigger array LOADING_PARTS_OF_]]..name..[[   
		static integer LOADING_PARTS_OF_]]..name..[[_COUNT = ARRAY_EMPTY

		static integer array LOADING_PARTS_OF_]]..name..[[_CODE_ID
		static string array LOADING_PARTS_OF_]]..name..[[_NAME

		static method AddInit_]]..name..[[ takes code c, string name returns nothing
			set LOADING_PARTS_OF_]]..name..[[_COUNT = LOADING_PARTS_OF_]]..name..[[_COUNT + 1
			set LOADING_PARTS_OF_]]..name..[[[LOADING_PARTS_OF_]]..name..[[_COUNT] = CreateTrigger()

			set LOADING_PARTS_OF_]]..name..[[_CODE_ID[LOADING_PARTS_OF_]]..name..[[_COUNT] = Code.GetId(c)
			set LOADING_PARTS_OF_]]..name..[[_NAME[LOADING_PARTS_OF_]]..name..[[_COUNT] = name

			call TriggerAddCondition(LOADING_PARTS_OF_]]..name..[[[LOADING_PARTS_OF_]]..name..[[_COUNT], Condition(c))
		endmethod

		static method RunInits_]]..name..[[_LabelTrig takes nothing returns boolean
			//call Loading.Load(]]..name:quote()..[[, 0)

			return true
		endmethod

		static method RunInits_]]..name..[[ takes nothing returns boolean
			local integer iteration = LOADING_PARTS_OF_]]..name..[[_COUNT

			loop
				exitwhen (iteration < ARRAY_MIN)

				call Loading.Queue(LOADING_PARTS_OF_]]..name..[[[iteration], LOADING_PARTS_OF_]]..name..[[_CODE_ID[iteration], LOADING_PARTS_OF_]]..name..[[_NAME[iteration])

				set iteration = iteration - 1
			endloop

			return true
		endmethod
	]])

	f:write('\n'..name)

	for i = 1, #part.inits, 1 do
		f:write('\n\t'..part.inits[i]:getPath())
	end
end

f:close()

addLine([[
    static string array DUMMY_STRINGS
    static real DURATION
    static boolean ENDING = false

    static method Ending2 takes nothing returns nothing
        set thistype.ENDING = true
        call FogEnable(true)
        call FogMaskEnable(true)
        call ResetToGameCamera(0.)
        call ResetTerrainFog()
        call SetCameraField(CAMERA_FIELD_FARZ, 5000., 0.)
        call DisplayCineFilter(false)

        call EnableUserUI(true)

        call InfoEx("finished loading in " + R2S(thistype.DURATION) + " seconds")

        call PauseGame(false)
    endmethod

    static method Ending takes nothing returns nothing
        call SetCameraField(CAMERA_FIELD_FARZ, 0., 0.)

        call SetCineFilterBlendMode(BLEND_MODE_BLEND)
        call SetCineFilterTexMapFlags(TEXMAP_FLAG_NONE)
        call SetCineFilterDuration(Initialization.START_DELAY - 1.)
        call SetCineFilterEndColor(255, 255, 255, 0)
        call SetCineFilterStartColor(255, 255, 255, 255)
        call SetCineFilterEndUV(0, 0, 1, 1)
        call SetCineFilterStartUV(0, 0, 1, 1)
        call SetCineFilterTexture("UI\\LoadingScreenBackground.blp")

        call DisplayCineFilter(true)

        call ShowInterface(true, Initialization.START_DELAY - 1.)
    endmethod

    static constant real HEIGHT = 10000.

    static method UpdateCam_Exec takes nothing returns nothing
        call SetTerrainFogEx(0, thistype.HEIGHT, thistype.HEIGHT, 0, 0, 0, 0)
        call SetCameraField(CAMERA_FIELD_FARZ, thistype.HEIGHT, 0.)

        loop
            exitwhen thistype.ENDING

            call SetCameraField(CAMERA_FIELD_ANGLE_OF_ATTACK, 270., 0.)
            call SetCameraField(CAMERA_FIELD_TARGET_DISTANCE, 1650., 0.)
            call SetCameraField(CAMERA_FIELD_ZOFFSET, thistype.HEIGHT, 0.)

            call TriggerSleepAction(0.035)
        endloop
    endmethod

    static integer LOADING_PARTS_AMOUNT_PER_PERCENT
    //! runtextmacro CreateQueue("QUEUED")
    static timer QUEUE_TIMER

    implement Allocation
    implement Name

    integer codeId
    string name
    trigger trig

    static method Queue_Exec takes nothing returns nothing
        local integer cur
        local integer i = thistype.LOADING_PARTS_AMOUNT_PER_PERCENT
        local integer max
        local thistype this

        if thistype.QUEUED_IsEmpty() then
            return
        endif

        loop
            exitwhen thistype.QUEUED_IsEmpty()

            set this = thistype.QUEUED_FetchFirst()

            call IncStack(this.codeId)

            if not TriggerEvaluate(this.trig) then
                call DebugEx("LoadingQueue", "Queue_Exec", "could not finish init: " + this.name)
            endif

            call DecStack()

            //call DestroyTrigger(this.trig)

            set this.trig = null

            set i = i - 1
            exitwhen (i < 1)
        endloop

        set cur = thistype.LOADING_PARTS_AMOUNT - thistype.QUEUED_Amount()
        set max = thistype.LOADING_PARTS_AMOUNT

        call SetCinematicScene(0, null, "Please wait for the map to initialize...", I2S(cur) + "/" + I2S(max) + " assets loaded" + Char.BREAK + I2S(R2I(cur * 100. / max)) + Char.PERCENT, 999, 0)

        if thistype.QUEUED_IsEmpty() then
            call PauseTimer(thistype.QUEUE_TIMER)
        endif
    endmethod

    static method Queue takes trigger t, integer codeId, string name returns nothing
        local thistype this = thistype.allocCustom()

        set thistype.LOADING_PARTS_AMOUNT = thistype.LOADING_PARTS_AMOUNT + 1

	set this.codeId = codeId
        set this.name = name
        set this.trig = t

        call thistype.QUEUED_Add(this)
    endmethod

    static method QueueCode takes code c returns nothing
        local string name = LoadStr(FUNCS_TABLE, Code.GetId(c), 0)
        local trigger t = CreateTrigger()

        set thistype.LOADING_PARTS_AMOUNT = thistype.LOADING_PARTS_AMOUNT + 1

        call TriggerAddCondition(t, Condition(c))

        if (name == null) then
            set name = "unknown"
        endif

        call thistype.Queue(t, Code.GetId(c), name)

        set t = null
    endmethod

    static method IsSinglePlayer takes nothing returns boolean
        local gamecache gc = InitGameCache("singlePlayerCheck")
        local boolean result

        call StoreBoolean(gc, "blub", "moo", true)

        set result = SaveGameCache(gc)

        call FlushGameCache(gc)

        set gc = null

        return result
    endmethod

    static method IsSinglePlayer2 takes nothing returns boolean
        local integer c = 0
        local integer i = 15

        loop
            exitwhen (i < 0)

            if ((GetPlayerController(Player(i)) == MAP_CONTROL_USER) and (GetPlayerSlotState(Player(i)) == PLAYER_SLOT_STATE_PLAYING)) then
                set c = c + 1
            endif

            set i = i - 1
        endloop

        return (c < 2)
    endmethod

    static method ExecQueue_Exec takes nothing returns nothing
        local integer amount = thistype.QUEUED_Amount()
        local integer userCount

        if (amount <= 0) then
            return
        endif

        set thistype.LOADING_PARTS_AMOUNT = amount
        set thistype.LOADING_PARTS_AMOUNT_PER_PERCENT = R2I(amount / 100.)

        if IsSinglePlayer() then
            call InfoEx("singlePlayer")
            call PauseGame(true)

            loop
                exitwhen thistype.ENDING

                call ExecuteFunc(thistype.Queue_Exec.name)
                call ExecuteFunc(thistype.Queue_Exec.name)
                call ExecuteFunc(thistype.Queue_Exec.name)
                call ExecuteFunc(thistype.Queue_Exec.name)
                call ExecuteFunc(thistype.Queue_Exec.name)

                call TriggerSleepAction(0)
            endloop
        else
            call TimerStart(thistype.QUEUE_TIMER, 1. / 12, true, function thistype.Queue_Exec)
        endif
    endmethod

    static method ExecQueue takes nothing returns nothing
        call ExecuteFunc(thistype.ExecQueue_Exec.name)
    endmethod

    static method WaitLoop takes nothing returns nothing
        set thistype.DURATION = 0

        loop
            exitwhen thistype.ENDING

            call TriggerSleepAction(1)

            set thistype.DURATION = thistype.DURATION + 1
        endloop
    endmethod

    static method Start takes nothing returns nothing
        local real camX = GetCameraTargetPositionX()
        local real camY = GetCameraTargetPositionY()
        local real z = 3900.

        call EnableUserUI(false)
        call ShowInterface(false, 1)

        call SetCineFilterBlendMode(BLEND_MODE_BLEND)
        call SetCineFilterTexMapFlags(TEXMAP_FLAG_NONE)
        call SetCineFilterDuration(0)
        call SetCineFilterEndColor(255, 255, 255, 255)
        call SetCineFilterStartColor(255, 255, 255, 255)
        call SetCineFilterEndUV(0, 0, 1, 1)
        call SetCineFilterStartUV(0, 0, 1, 1)
        call SetCineFilterTexture("UI\\LoadingScreenBackground.blp")

        call DisplayCineFilter(true)

        call FogEnable(false)
        call FogMaskEnable(false)
//        call SetCameraBounds(camX, camY, camX, camY, camX, camY, camX, camY)

        call ExecuteFunc(thistype.UpdateCam_Exec.name)
        call ExecuteFunc(thistype.WaitLoop.name)
    endmethod

    static method Init takes nothing returns nothing
        set thistype.QUEUE_TIMER = CreateTimer()
    endmethod
endstruct
]])

--initFuncs
addLine([[
struct InitCommon
	static method onInit takes nothing returns nothing
		local ObjThread t = ObjThread.Create("InitCommon")
]])

addLine([[
		call t.Destroy()
	endmethod
endstruct
]])

addLine([[
	globals
		hashtable FUNCS_TABLE
	endglobals
]])