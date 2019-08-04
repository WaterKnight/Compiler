scope Constants
    globals
        constant integer ARRAY_MAX = 8191
        constant integer ARRAY_MIN = 0
        constant integer ARRAY_SIZE = 8192
        constant integer COMMAND_FIELD_SIZE = 12
        constant boolean DEBUG = true
        constant integer FRAMES_PER_SECOND_AMOUNT = 64
        constant integer FRAMES_PER_SECOND_HUMAN_EYE_AMOUNT = 32
        constant real INFINITE_DURATION = -1.
        constant integer MAX_INVENTORY_SIZE = 6
        constant integer STRUCT_MAX = 8190
        constant integer STRUCT_MIN = 1

        constant integer ARRAY_EMPTY = ARRAY_MIN - 1
        constant real FRAME_UPDATE_TIME = 1. / FRAMES_PER_SECOND_AMOUNT
        constant integer STRUCT_BASE = STRUCT_MAX + 1
        constant integer STRUCT_EMPTY = STRUCT_MIN - 1

        constant integer NULL = STRUCT_EMPTY
        constant integer STRUCT_INVALID = STRUCT_EMPTY - 1

        constant real WORLD_MAX_X = 8192
        constant real WORLD_MIN_X = -8192
        constant real WORLD_MAX_Y = 8192
        constant real WORLD_MIN_Y = -8192
    endglobals
endscope

function GetExpiredTimerSafe takes nothing returns timer
	if (GetTriggerEventId() != null) then
		return null
	endif

	return GetExpiredTimer()
endfunction

scope DebugExScope
    globals
        boolean DEBUG_EX_ON = true
        integer DEBUG_EX_COUNT = 0
        integer DEBUG_EX_COUNT_MAX_PER_FILE = 500
        timer DEBUG_EX_TIMER = CreateTimer()
        integer SESSION_ID = -1
    endglobals

    function DebugMsg takes string s returns nothing
        call DisplayTimedTextToPlayer(GetLocalPlayer(), 0., 0., 10., s)
    endfunction

    function GetDebugTime takes nothing returns real
        return TimerGetElapsed(DEBUG_EX_TIMER)
    endfunction

    function OutputLine takes string s returns nothing
        set DEBUG_EX_COUNT = DEBUG_EX_COUNT + 1

        if ((DEBUG_EX_COUNT div DEBUG_EX_COUNT_MAX_PER_FILE) != ((DEBUG_EX_COUNT - 1) div DEBUG_EX_COUNT_MAX_PER_FILE)) then
            call PreloadGenClear()
        endif

		set s = "#" + I2S(DEBUG_EX_COUNT) + " (" + R2S(GetDebugTime()) + "): " + s

		local string s2 = "\")" + s

		if (StringLength(s2) > 259) then
			local integer length = StringLength(s)

			local integer c = length div 257 + 1
			local integer i = 1

			call Preload("\")" + ":cmd mergeLines=" + I2S(c))

			loop
				exitwhen (i > c)

				if (i == c) then
					call Preload("\")" + SubString(s, (i - 1) * 257, length))
				else
					call Preload("\")" + SubString(s, (i - 1) * 257, i * 257 + 1))
				endif

				set i = i + 1
			endloop
		else
			call Preload(s2)
		endif

        call PreloadGenEnd("Logs\\Defend Wintercastle\\Session" + I2S(SESSION_ID) + "\\DWC_Errors_" + I2S(DEBUG_EX_COUNT div DEBUG_EX_COUNT_MAX_PER_FILE) + ".txt")
    endfunction

    function InfoEx takes string s returns nothing
        local boolean isDebugPlayer = true//(GetPlayerName(GetLocalPlayer()) == "WaterKnight") or (GetPlayerName(GetLocalPlayer()) == "WaterServant") or (GetLocalPlayer() == Player(0))

        if (s == null) then
            set s = "null"
        endif

        if not isDebugPlayer then
            return
        endif

        call OutputLine("[INFO] " + s)
    endfunction

    function Debug takes string s returns nothing
        local boolean isDebugPlayer = true//(GetPlayerName(GetLocalPlayer()) == "WaterKnight") or (GetPlayerName(GetLocalPlayer()) == "WaterServant") or (GetLocalPlayer() == Player(0))

        if (s == null) then
            set s = "null"
        endif

        //call SetPlayerState(GetLocalPlayer(), PLAYER_STATE_RESOURCE_FOOD_USED, DEBUG_EX_COUNT)

        if isDebugPlayer then
            //call DebugMsg(s)
        endif

        //if Nullboard.LOG_INITED then
            //call Nullboard.WriteLogLine(s)
        //endif

        if not isDebugPlayer then
            return
        endif

        call OutputLine("[DEBUG] " + s)
    endfunction

	globals
		string array DEBUG_BUFFER
		integer DEBUG_BUFFER_COUNT = ARRAY_EMPTY
		integer DEBUG_BUFFER_NESTING = 0
	endglobals

	function DebugBuffer takes string s returns nothing
		set DEBUG_BUFFER_COUNT = DEBUG_BUFFER_COUNT + 1
		set DEBUG_BUFFER[DEBUG_BUFFER_COUNT] = s
	endfunction

	function DebugBufferFinish takes nothing returns nothing
		local integer i = DEBUG_BUFFER_COUNT - 1
		local string s

		set DEBUG_BUFFER_NESTING = DEBUG_BUFFER_NESTING - 1

		if (DEBUG_BUFFER_NESTING > 0) then
			return
		endif

		if (DEBUG_BUFFER_COUNT < ARRAY_MIN) then
			return
		endif

 		set s = DEBUG_BUFFER[DEBUG_BUFFER_COUNT]

		set DEBUG_BUFFER_COUNT = ARRAY_EMPTY

		loop
			exitwhen (i < ARRAY_MIN)

			set s = DEBUG_BUFFER[i] + Char.BREAK + Char.TAB + s

			set i = i - 1
		endloop

		call Debug(s)
	endfunction

	function DebugBufferStart takes nothing returns nothing
		//call DebugBufferFinish()
		set DEBUG_BUFFER_NESTING = DEBUG_BUFFER_NESTING + 1
	endfunction

    function DebugFile takes string path, string s returns nothing
        local boolean isDebugPlayer = true//(GetPlayerName(GetLocalPlayer()) == "WaterKnight") or (GetPlayerName(GetLocalPlayer()) == "WaterServant") or (GetLocalPlayer() == Player(0))

        if (s == null) then
            set s = "null"
        endif

        if isDebugPlayer then
            //call DebugMsg(s)
        endif

        //if Nullboard.LOG_INITED then
            //call Nullboard.WriteLogLine(s)
        //endif

        if not isDebugPlayer then
            return
        endif

    //call PreloadGenClear()

    //call PreloadGenStart()

        set DEBUG_EX_COUNT = DEBUG_EX_COUNT + 1

        call Preload("#" + I2S(DEBUG_EX_COUNT) + " (" + R2S(TimerGetElapsed(DEBUG_EX_TIMER)) + "): " + s)

        call PreloadGenEnd(path)
    endfunction

    private function PreloadBatLine takes string s returns nothing
        call Preload("\")\n" + s + "\nREM (\"")
    endfunction

	globals
		integer array RUN_STACK
		integer RUN_STACK_COUNT = ARRAY_EMPTY
	endglobals

	function GetStackString takes nothing returns string
		local string result = ""

		local integer i = RUN_STACK_COUNT

		if (GetExpiredTimerSafe() != null) then
			set result = "-> " + Timer.GetFromSelf(GetExpiredTimerSafe()).GetName()
		endif

		loop
			exitwhen (i < ARRAY_MIN)

			if (result == "") then
				//set result = "-> " + RUN_STACK[i].GetNameEx()
				set result = "-> " + Code.GetNameById(RUN_STACK[i])
			else
				//set result = result + Char.BREAK + "-> " + RUN_STACK[i].GetNameEx()
				set result = result + Char.BREAK + "-> " + Code.GetNameById(RUN_STACK[i])
			endif

			set i = i - 1
		endloop

		return "stack trace:" + Char.BREAK + result
	endfunction

	function PrintBufferStack takes nothing returns nothing
		local integer i = RUN_STACK_COUNT

		call DebugBuffer("stack trace:")

		//if (GetExpiredTimerSafe() != null) then
			//call DebugBuffer("-> " + Timer.GetFromSelf(GetExpiredTimerSafe()).GetName())
		//endif

		loop
			exitwhen (i < ARRAY_MIN)

			//call DebugBuffer("-> " + RUN_STACK[i].GetNameEx())
			call DebugBuffer("-> " + Code.GetNameById(RUN_STACK[i]))

			set i = i - 1
		endloop
	endfunction

	function DecStack takes nothing returns nothing
		set RUN_STACK_COUNT = RUN_STACK_COUNT - 1
	endfunction

	function IncStack takes integer codeId returns nothing
		set RUN_STACK_COUNT = RUN_STACK_COUNT + 1
		set RUN_STACK[RUN_STACK_COUNT] = codeId
	endfunction

	function DebugEx takes string source, string line, string s returns nothing
		call DebugBufferStart()

		call DebugBuffer("---/")

		if (s != null) then
			call DebugBuffer(s)
		endif

		call DebugBuffer("")

		if (source != null) then
			call DebugBuffer("in ->" + source)
		endif
		if (line != null) then
			call DebugBuffer("line ->" + line)
		endif

		call DebugBuffer("")

		call PrintBufferStack()

		call DebugBuffer("/---")

		call DebugBufferFinish()
	endfunction

	function PrintStack takes nothing returns nothing
		call DebugEx(null)
	endfunction

    private function init_debugInit takes nothing returns nothing
        local string prevToDScale = GetPlayerName(GetLocalPlayer())

        call TimerStart(DEBUG_EX_TIMER, 99999, true, null)

        call SetPlayerName(GetLocalPlayer(), I2S(SESSION_ID))

		call PreloadGenClear()
		call Preloader("Logs\\Defend Wintercastle\\index.ini")

        set SESSION_ID = S2I(GetPlayerName(GetLocalPlayer())) + 1

        call PreloadGenClear()
        call PreloadGenStart()

        call Preload("\")\n" + "call SetPlayerName(GetLocalPlayer(), \"" + I2S(SESSION_ID) + "\")" + "\ncall Preload(\"")

        call SetPlayerName(GetLocalPlayer(), prevToDScale)

        call PreloadGenEnd("Logs\\Defend Wintercastle\\index.ini")

        call PreloadGenEnd("Logs\\Defend Wintercastle\\signal.ini")

        call PreloadGenClear()

        call PreloadBatLine("DEL \"DWC_Errors.txt\"")

        call PreloadBatLine("DEL takeFile.bat")

        call PreloadBatLine("echo	set file=%%~1>>takeFile.bat")
        call PreloadBatLine("echo	echo %%file%%>>takeFile.bat")
        call PreloadBatLine("echo	for /f \"tokens=*\" %%%%A in (%%file%%) do (call takeLine.bat \"%%%%A\")>>takeFile.bat")
        call PreloadBatLine("REM echo	DEL %%file%%>>takeFile.bat")

        call PreloadBatLine("DEL takeLine.bat")

        call PreloadBatLine("echo	set txt=%%1>>takeLine.bat")
        call PreloadBatLine("echo	set txt=%%txt:call Preload( ^\"^\")=%%>>takeLine.bat")

        call PreloadBatLine("echo	IF %%txt%%==%%1 goto :eof>>takeLine.bat")

        call PreloadBatLine("echo	set txt=%%txt:^\" )=%%>>takeLine.bat")

        call PreloadBatLine("echo	set txt=%%txt:^|=^^^^^^^|%%>>takeLine.bat")
        call PreloadBatLine("echo	set txt=%%txt:^>=^^^^^^^>%%>>takeLine.bat")
        call PreloadBatLine("echo	set txt=%%txt:^\"='%%>>takeLine.bat")

        call PreloadBatLine("echo	IF \"%%txt%%\"==\"\" goto :eof>>takeLine.bat")

        call PreloadBatLine("echo	echo %%txt%%^>^>DWC_Errors.txt>>takeLine.bat")

        call PreloadBatLine("pause")

        call PreloadBatLine("for /f %%f in ('dir /b /od \"DWC_Errors_*.txt\"') do (call takeFile.bat \"%%f\")")

        call PreloadBatLine("DEL takeFile.bat")
        call PreloadBatLine("DEL takeLine.bat")

        call PreloadGenEnd("Logs\\Defend Wintercastle\\Session" + I2S(SESSION_ID) + "\\DWC_Errors_MergeLogs.bat")

        call PreloadGenClear()

        call InfoEx("private session "+I2S(SESSION_ID))

		call Basic.Init()
    endfunction
endscope

struct Basic
    static integer ALLOCATED_OBJS_COUNT = 0
    static integer NATIVE_OBJS_COUNT = 0

	static multiboard ALLOC_MB

    static method onRemoveUnit takes unit u returns nothing
        if (u == null) then
                call DebugEx("Basic.onRemoveUnit: invalid unit")
            return
        endif

        set thistype.NATIVE_OBJS_COUNT = thistype.NATIVE_OBJS_COUNT - 1
    endmethod

    static method onCreateUnit takes player p, integer id, real x, real y, real z returns nothing
        set thistype.NATIVE_OBJS_COUNT = thistype.NATIVE_OBJS_COUNT + 1
    endmethod

	static hashtable STRUCT_TABLE = null
	static integer STRUCT_ALLOC_COUNT_RESULT

	static string array STRUCT_NAMES
	static integer STRUCT_NAMES_COUNT = ARRAY_EMPTY

	static method GetStructAllocCount takes string name returns integer
		local trigger t = LoadTriggerHandle(thistype.STRUCT_TABLE, 0, StringHash(name))

		if (t == null) then
			return -1
		endif

		set thistype.STRUCT_ALLOC_COUNT_RESULT = -1

		call TriggerEvaluate(t)

		return thistype.STRUCT_ALLOC_COUNT_RESULT
	endmethod

	static method AddStruct takes string name, code allocCountFunc returns nothing
		if (thistype.STRUCT_TABLE == null) then
			set thistype.STRUCT_TABLE = InitHashtable()
		endif

		local trigger t = CreateTrigger()

		call TriggerAddCondition(t, Condition(allocCountFunc))

		call SaveTriggerHandle(thistype.STRUCT_TABLE, 0, StringHash(name), t)

		set t = null

		set thistype.STRUCT_NAMES_COUNT = thistype.STRUCT_NAMES_COUNT + 1
		set thistype.STRUCT_NAMES[thistype.STRUCT_NAMES_COUNT] = name
	endmethod

	//private static multiboarditem ALLOC_MB_HEAD_NAME
	//private static multiboarditem ALLOC_MB_HEAD_VAL

	static integer ALLOC_MODULES_COUNT = ARRAY_EMPTY
	static integer ALLOC_MODULES_AMOUNT = 0

	static integer array ALLOC_MODULES_ALLOC_COUNT
	static string array ALLOC_MODULES_NAME

	static integer ALLOC_MODULES_ALLOC_QUEUE_FIRST = ARRAY_EMPTY
	static integer array ALLOC_MODULES_ALLOC_QUEUE_FIRST_OF
	static integer ALLOC_MODULES_ALLOC_QUEUE_LAST = ARRAY_EMPTY
	static integer array ALLOC_MODULES_ALLOC_QUEUE_LAST_OF

	static integer array ALLOC_MODULES_ALLOC_QUEUE_NEXT
	static integer array ALLOC_MODULES_ALLOC_QUEUE_PREV

	integer allocModulesAllocQueue_next
	integer allocModulesAllocQueue_prev

	static trigger GET_ALLOC_MODULE_FROM_QUEUE_EXEC

	static integer GET_ALLOC_MODULE_FROM_QUEUE_ARG_OFFSET
	static integer GET_ALLOC_MODULE_FROM_QUEUE_RETURN

	execMethod GetAllocModuleFromQueue_Exec
		local integer offset = thistype.GET_ALLOC_MODULE_FROM_QUEUE_ARG_OFFSET

		local integer cur = thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST

		set offset = offset - 1

		loop
			exitwhen (offset < ARRAY_MIN)

			set cur = thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[cur]

			set offset = offset - 1
		endloop

		set thistype.GET_ALLOC_MODULE_FROM_QUEUE_RETURN = cur
	endmethod

	static method GetAllocModuleFromQueue takes integer offset returns integer
		set thistype.GET_ALLOC_MODULE_FROM_QUEUE_ARG_OFFSET = offset

		if not TriggerEvaluate(thistype.GET_ALLOC_MODULE_FROM_QUEUE_EXEC) then
			call DebugEx("GetAllocModuleFromQueue: " + "thread broken")
		endif

		return thistype.GET_ALLOC_MODULE_FROM_QUEUE_RETURN
	endmethod

	static method GetAllocModuleAllocCount takes integer index returns integer
		return thistype.ALLOC_MODULES_ALLOC_COUNT[index]
	endmethod

	static method GetAllocModuleName takes integer index returns string
		return thistype.ALLOC_MODULES_NAME[index]
	endmethod

	static method PrintAllocModules takes nothing returns nothing
		local integer cur = thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST

		loop
			exitwhen (cur == ARRAY_EMPTY)

			call DebugEx(thistype.GetAllocModuleName(cur))

			set cur = thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[cur]
		endloop
	endmethod

	static integer ALLOC_DEC_ARG_INDEX
	static trigger ALLOC_DEC_EXEC

	execMethod AllocDec_Exec
		local integer index = thistype.ALLOC_DEC_ARG_INDEX

		local integer oldCount = thistype.ALLOC_MODULES_ALLOC_COUNT[index]
		local integer newCount = oldCount - 1

		if (newCount < 0) then
			call DebugEx("AllocDec: cannot fall below zero")

			return
		endif

		set thistype.ALLOC_MODULES_ALLOC_COUNT[index] = newCount

		local integer firstOf = thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST_OF[oldCount]
		local integer lastOf = thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST_OF[oldCount]

		local integer oldPrev = thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[index]
		local integer oldNext = thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[index]
		local integer newPrev

		if (lastOf == index) then
			if (firstOf == index) then
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST_OF[oldCount] = ARRAY_EMPTY
			else
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST_OF[oldCount] = oldPrev
			endif

			set newPrev = ARRAY_EMPTY
		else
			set newPrev = lastOf
		endif
		if (firstOf == index) then
			if (lastOf == index) then
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST_OF[oldCount] = ARRAY_EMPTY
			else
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST_OF[oldCount] = oldNext
			endif
		endif

		if (newPrev != ARRAY_EMPTY) then		
			if (oldNext != ARRAY_EMPTY) then
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[oldNext] = oldPrev
			endif
			if (oldPrev == ARRAY_EMPTY) then
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST = oldNext
			else
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[oldPrev] = oldNext
			endif

			local integer newNext = thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[newPrev]

			set thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[index] = newNext
			if (newNext == ARRAY_EMPTY) then
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST = index
			else
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[newNext] = index
			endif

			set thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[newPrev] = index
			set thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[index] = newPrev
		endif

		if ((index == thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST) or (thistype.ALLOC_MODULES_ALLOC_COUNT[thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[index]] < newCount)) then
			set thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST_OF[newCount] = index
		endif
		set thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST_OF[newCount] = index

		//call MultiboardSetItemValue(thistype.ALLOC_MB_ITEM, I2S(thistype.ALLOC_MODULES_ALLOC_COUNT[index]))

        set thistype.ALLOCATED_OBJS_COUNT = thistype.ALLOCATED_OBJS_COUNT - 1
	endmethod

	static method AllocDec takes integer index returns nothing
		set thistype.ALLOC_DEC_ARG_INDEX = index

		if not TriggerEvaluate(thistype.ALLOC_DEC_EXEC) then
			call DebugEx("AllocDec: " + "thread broken")
		endif
	endmethod

	static integer ALLOC_INC_ARG_INDEX
	static trigger ALLOC_INC_EXEC

	execMethod AllocInc_Exec
		local integer index = thistype.ALLOC_INC_ARG_INDEX

		local integer oldCount = thistype.ALLOC_MODULES_ALLOC_COUNT[index]
		local integer newCount = oldCount + 1

		set thistype.ALLOC_MODULES_ALLOC_COUNT[index] = newCount

		local integer firstOf = thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST_OF[oldCount]
		local integer lastOf = thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST_OF[oldCount]

		local integer oldNext = thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[index]
		local integer oldPrev = thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[index]
		local integer newNext

		if (firstOf == index) then
			if (lastOf == index) then
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST_OF[oldCount] = ARRAY_EMPTY
			else
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST_OF[oldCount] = oldNext
			endif

			set newNext = ARRAY_EMPTY
		else
			set newNext = firstOf
		endif
		if (lastOf == index) then
			if (firstOf == index) then
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST_OF[oldCount] = ARRAY_EMPTY
			else
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST_OF[oldCount] = oldPrev
			endif
		endif

		if (newNext != ARRAY_EMPTY) then
			if (oldPrev != ARRAY_EMPTY) then
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[oldPrev] = oldNext
			endif
			if (oldNext == ARRAY_EMPTY) then
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST = oldPrev
			else
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[oldNext] = oldPrev
			endif

			local integer newPrev = thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[newNext]

			set thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[index] = newPrev
			if (newPrev == ARRAY_EMPTY) then
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST = index
			else
				set thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[newPrev] = index
			endif

			set thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[newNext] = index
			set thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[index] = newNext
		endif

		if ((index == thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST) or (thistype.ALLOC_MODULES_ALLOC_COUNT[thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[index]] > newCount)) then
			set thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST_OF[newCount] = index
		endif
		set thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST_OF[newCount] = index

		//call MultiboardSetItemValue(thistype.ALLOC_MB_ITEM, I2S(thistype.ALLOC_MODULES_ALLOC_COUNT[index]))

        set thistype.ALLOCATED_OBJS_COUNT = thistype.ALLOCATED_OBJS_COUNT + 1
	endmethod

	static method AllocInc takes integer index returns nothing
		set thistype.ALLOC_INC_ARG_INDEX = index

		if not TriggerEvaluate(thistype.ALLOC_INC_EXEC) then
			call DebugEx("AllocInc: " + "thread broken")
		endif
	endmethod

	static method RegAllocModule takes string name returns integer
		set thistype.ALLOC_MODULES_AMOUNT = thistype.ALLOC_MODULES_AMOUNT + 1

		local integer index = thistype.ALLOC_MODULES_COUNT + 1

		set thistype.ALLOC_MODULES_COUNT = index

		set thistype.ALLOC_MODULES_ALLOC_COUNT[index] = 0
		set thistype.ALLOC_MODULES_NAME[index] = name

		if (thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST == ARRAY_EMPTY) then
			set thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST = index

			set thistype.ALLOC_MODULES_ALLOC_QUEUE_FIRST_OF[0] = index
		else
			set thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST] = index
		endif

		set thistype.ALLOC_MODULES_ALLOC_QUEUE_NEXT[index] = ARRAY_EMPTY
		set thistype.ALLOC_MODULES_ALLOC_QUEUE_PREV[index] = thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST

		set thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST = index
		set thistype.ALLOC_MODULES_ALLOC_QUEUE_LAST_OF[0] = index

		return index
	endmethod

	static method Init takes nothing returns nothing
		set thistype.GET_ALLOC_MODULE_FROM_QUEUE_EXEC = CreateTrigger()
		set thistype.ALLOC_DEC_EXEC = CreateTrigger()
		set thistype.ALLOC_INC_EXEC = CreateTrigger()

		call TriggerAddCondition(thistype.GET_ALLOC_MODULE_FROM_QUEUE_EXEC, function thistype.GetAllocModuleFromQueue_Exec)
		call TriggerAddCondition(thistype.ALLOC_DEC_EXEC, function thistype.AllocDec_Exec)
		call TriggerAddCondition(thistype.ALLOC_INC_EXEC, function thistype.AllocInc_Exec)
	endmethod
endstruct

hook RemoveUnit Basic.onRemoveUnit
hook CreateUnit Basic.onCreateUnit

//! textmacro CreateTimeByFramesAmount takes var, framesAmount
    static constant real $var$ = FRAME_UPDATE_TIME * $framesAmount$
    static constant integer $var$_FRAMES_AMOUNT = $framesAmount$
//! endtextmacro

//! textmacro CreateHumanEyeTime takes var, factor
    static constant real $var$ = ($factor$ * 1.) / FRAMES_PER_SECOND_HUMAN_EYE_AMOUNT
    static constant integer $var$_FRAMES_AMOUNT = R2I(FRAMES_PER_SECOND_HUMAN_EYE_AMOUNT / ($factor$ * 1.))
//! endtextmacro

function B2I takes boolean b returns integer
    if b then
        return 1
    endif

    return 0
endfunction

function B2S takes boolean b returns string
    if b then
        return "true"
    endif

    return "false"
endfunction

struct nest
	method abc takes nothing returns nothing
	endmethod

	struct nest2
		integer nest2_abc

		struct nest3
			integer nest3_abc
			integer nest3_def
		endstruct

		integer nest2_ghi
	endstruct
endstruct

//! textmacro Folder takes name
    scope Folder$name$
//! endtextmacro

//! textmacro LinkToStaticStruct takes folder, name
    static Folder$folder$_Struct$name$ $name$ = NULL
//! endtextmacro

globals
    trigger InitLinks_DUMMY_TRIGGER = CreateTrigger()
    integer InitLinks_ITERATION
    integer InitLinks_THREAD_BREAK_COUNTER
    constant integer InitLinks_THREAD_BREAK_LIMIT = 300
endglobals

//! textmacro LinkToStruct takes folder, struct
    Folder$folder$_Struct$struct$ $struct$ = this
    Folder$folder$_Struct$struct$ LinkToStruct_$struct$
//! endtextmacro

struct DataStub
	method Destroy takes nothing returns nothing
	endmethod
endstruct

struct EventStub
	method Destroy takes nothing returns nothing
	endmethod
endstruct

struct IdStub
	method Event_Create takes nothing returns nothing
	endmethod
endstruct

struct rootStruct
	DataStub Data
	EventStub Event
	IdStub Id
endstruct

module Allocation
	//delegate rootStruct rootStruct

	//private static integer ALLOC_COUNT = 0
	//private static multiboarditem ALLOC_MB_ITEM
    private static thistype NEXT = NULL
    private static integer array QUEUED
    private static integer QUEUED_COUNT = 0

    /*method deallocCustom takes nothing returns nothing
        static if DEBUG then
            if (this == NULL) then
                call DebugEx("alloc: try to deallocate NULL instance")

                return
            endif

            if (thistype.QUEUED[this] != STRUCT_INVALID) then
                call DebugEx("alloc: try to double-deallocate instance " + I2S(this))

                return
            endif
        endif

        set thistype.QUEUED[this] = thistype.NEXT

        set thistype.QUEUED_COUNT = this
    endmethod

    static method allocCustom takes nothing returns thistype
        local thistype this = thistype.NEXT

        if (this == NULL) then
            set thistype.QUEUED_COUNT = thistype.QUEUED_COUNT + 1

            set this = thistype.QUEUED_COUNT
        else
            set thistype.NEXT = thistype.QUEUED[this]
        endif

        static if DEBUG then
            if (integer(this) > STRUCT_MAX) then
                call DebugEx(thistype.NAME + " - alloc: unable to allocate, reached stack limit")

                return NULL
            endif
        endif

        set thistype.QUEUED[this] = STRUCT_INVALID

        return this
    endmethod*/

	/*static method allocCount takes nothing returns integer
		return thistype.ALLOC_COUNT
	endmethod

	static method allocCountEx takes nothing returns nothing
		set Basic.STRUCT_ALLOC_COUNT_RESULT = thistype.allocCount()
	endmethod*/

	//private static method onInit takes nothing returns nothing
	//	call Basic.AddStruct(thistype.NAME, thistype.AllocCountEx)
	//endmethod

    private static integer COUNT = STRUCT_EMPTY

    private thistype next

	private static integer ALLOC_MODULE_INDEX

	private static method allocInit_autoRun takes nothing returns nothing
		/*local integer row = MultiboardGetRowCount(Basic.ALLOC_MB)

		call MultiboardSetRowCount(Basic.ALLOC_MB, row + 1)

		set thistype.ALLOC_MB_ITEM = MultiboardGetItem(Basic.ALLOC_MB, row, 1)*/

		set thistype.ALLOC_MODULE_INDEX = Basic.RegAllocModule(thistype.NAME)
	endmethod

	public boolean allocation_allocated
	public boolean allocation_destroyed
	public integer allocation_refs

	method IsAllocated takes nothing returns boolean
		return this.allocation_allocated
	endmethod

	method CountRefs takes nothing returns integer
		return this.allocation_refs
	endmethod

	method deallocate_demount takes nothing returns nothing
		set this.allocation_allocated = false

		injectTarget hook

		call Basic.AllocDec(thistype.ALLOC_MODULE_INDEX)
	endmethod

    private method deallocCustom_confirm takes nothing returns nothing
		if (this.allocation_refs > 0) then
			return
		endif

        static if DEBUG then
            if (this.next != STRUCT_INVALID) then
                call DebugEx(thistype.NAME + " - alloc: unable to deallocate instance " + I2S(this))

                return
            endif
        endif

        set this.next = thistype(NULL).next

        set thistype(NULL).next = this

		call this.deallocate_demount()
    endmethod

	method subRef takes nothing returns nothing
		set this.allocation_refs = this.allocation_refs - 1

		call this.deallocCustom_confirm()
	endmethod

	method deallocCustom takes nothing returns nothing
		call this.subRef()
	endmethod

	static method allocate_mount takes thistype this returns thistype
		//static if thistype.Data.Destroy.exists then
			//call DebugEx("allocate_mount: "+thistype.NAME)
			//call this.Id.Event_Create()
		//endif

		set this.allocation_allocated = true
		set this.allocation_destroyed = false

		injectTarget hook

		call Basic.AllocInc(thistype.ALLOC_MODULE_INDEX)

		return this
	endmethod

	method addRef takes nothing returns nothing
		set this.allocation_refs = this.allocation_refs + 1
	endmethod

    static method allocCustom takes nothing returns thistype
        local thistype this

        static if DEBUG then
            if (thistype.QUEUED_COUNT == STRUCT_MAX) then
                call DebugEx(thistype.NAME + " - alloc: unable to allocate, reached stack limit")

                return NULL
            endif
        endif

        if (thistype(NULL).next == NULL) then
            set thistype.COUNT = thistype.COUNT + 1

            set this = thistype.COUNT
        else
            set this = thistype(NULL).next

            set thistype(NULL).next = thistype(NULL).next.next
        endif

        static if DEBUG then
            set this.next = STRUCT_INVALID
        endif

		set this.allocation_refs = 1

		call thistype.allocate_mount(this)

        return this
    endmethod
endmodule

module List
    static thistype array ALL
    static integer ALL_COUNT = ARRAY_EMPTY

    integer index

    method GetIndex takes nothing returns integer
        return this.index - 1
    endmethod

    method GetIndexInList takes nothing returns integer
        return this.index
    endmethod

    method IsInList takes nothing returns boolean
        return (this.GetIndexInList() > ARRAY_MIN)
    endmethod

    static method RandomFromList takes integer lowBound, integer highBound returns thistype
        return thistype.ALL[Math.RandomI(lowBound, highBound)]
    endmethod

    method RemoveFromList takes nothing returns boolean
        local integer index = this.GetIndexInList()

        set thistype.ALL[thistype.ALL_COUNT].index = index
        set thistype.ALL[index - 1] = thistype.ALL[thistype.ALL_COUNT]

        set this.index = ARRAY_MIN

        set thistype.ALL_COUNT = thistype.ALL_COUNT - 1

        return (thistype.ALL_COUNT == ARRAY_EMPTY)
    endmethod

    method RemoveFromListSafe takes nothing returns nothing
        if this.IsInList() then
            call this.RemoveFromList()
        endif
    endmethod

    method RemoveFromListSorted takes nothing returns boolean
        local integer iteration = this.GetIndexInList() - 1

        loop
            exitwhen (iteration == thistype.ALL_COUNT)

            set thistype.ALL[iteration] = thistype.ALL[iteration + 1]

            set thistype.ALL[iteration].index = iteration + 1

            set iteration = iteration + 1
        endloop

        set this.index = ARRAY_MIN

        set thistype.ALL_COUNT = thistype.ALL_COUNT - 1

        return (thistype.ALL_COUNT == ARRAY_EMPTY)
    endmethod

    method AddToList takes nothing returns boolean
        set thistype.ALL_COUNT = thistype.ALL_COUNT + 1

        set thistype.ALL[thistype.ALL_COUNT] = this
        set this.index = thistype.ALL_COUNT + 1

        return (thistype.ALL_COUNT == ARRAY_MIN)
    endmethod
endmodule

//! textmacro CreateList takes name
    static thistype array $name$_ALL
    static integer $name$_ALL_COUNT = ARRAY_EMPTY

    integer $name$_index

    static method $name$_Count takes nothing returns integer
        return thistype.$name$_ALL_COUNT
    endmethod

    static method $name$_IsEmpty takes nothing returns boolean
        return (thistype.$name$_Count() == ARRAY_EMPTY)
    endmethod

    static method $name$_Get takes integer index returns thistype
        return thistype.$name$_ALL[index]
    endmethod

    static method $name$_GetIndex takes thistype this returns integer
        return this.$name$_index
    endmethod

    static method $name$_Contains takes thistype this returns boolean
        return (thistype.$name$_GetIndex(this) > ARRAY_MIN)
    endmethod

    static method $name$_Random takes integer lowBound, integer highBound returns thistype
        return thistype.$name$_ALL[Math.RandomI(lowBound, highBound)]
    endmethod

    static method $name$_RandomAll takes nothing returns thistype
        return thistype.$name$_Random(ARRAY_MIN, thistype.$name$_ALL_COUNT)
    endmethod

    static method $name$_Remove takes thistype this returns boolean
        if not thistype.$name$_Contains(this) then
            return false
        endif

        set thistype.$name$_ALL[thistype.$name$_ALL_COUNT].$name$_index = this.$name$_index
        set thistype.$name$_ALL[this.$name$_index - 1] = thistype.$name$_ALL[thistype.$name$_ALL_COUNT]

        set this.$name$_index = ARRAY_MIN

        set thistype.$name$_ALL_COUNT = thistype.$name$_ALL_COUNT - 1

        return (thistype.$name$_ALL_COUNT == ARRAY_EMPTY)
    endmethod

    static method $name$_Add takes thistype this returns boolean
        if thistype.$name$_Contains(this) then
            return false
        endif

        set thistype.$name$_ALL_COUNT = thistype.$name$_ALL_COUNT + 1

        set thistype.$name$_ALL[thistype.$name$_ALL_COUNT] = this
        set this.$name$_index = thistype.$name$_ALL_COUNT + 1

        return (thistype.$name$_ALL_COUNT == ARRAY_MIN)
    endmethod
//! endtextmacro

//! textmacro CreateForEachList takes name, parent
    static thistype array $name$_ALL
    static integer $name$_ALL_COUNT = ARRAY_EMPTY

    static method $name$_FetchFirst takes nothing returns thistype
        local thistype result

        if (thistype.$name$_ALL_COUNT < ARRAY_MIN) then
            return NULL
        endif

        set result = thistype.$name$_ALL[ARRAY_MIN]

        set thistype.$name$_ALL[ARRAY_MIN] = thistype.$name$_ALL[thistype.$name$_ALL_COUNT]

        set thistype.$name$_ALL_COUNT = thistype.$name$_ALL_COUNT - 1

        return result
    endmethod

    static method $name$_Set takes nothing returns nothing
        local integer iteration = thistype.$parent$_ALL_COUNT

        loop
            exitwhen (iteration < ARRAY_MIN)

            set thistype.$name$_ALL[iteration] = thistype.$parent$_ALL[iteration]

            set iteration = iteration - 1
        endloop
        set thistype.$name$_ALL_COUNT = thistype.$parent$_ALL_COUNT
    endmethod
//! endtextmacro

//! textmacro CreateQueue takes name
    static thistype $name$_LAST = NULL
    static thistype $name$_NEXT = NULL

    thistype $name$_next
    thistype $name$_prev

    static method $name$_IsEmpty takes nothing returns boolean
        return (thistype.$name$_NEXT == NULL)
    endmethod

    static method $name$_Contains takes thistype this returns boolean
        if (thistype.$name$_NEXT == this) then
            return true
        endif

        if ((this.$name$_prev != NULL) or (this.$name$_next != NULL)) then
            return true
        endif

        return false
    endmethod

    static method $name$_Count takes nothing returns integer
        local integer iteration = ARRAY_EMPTY
        local thistype this = thistype.$name$_NEXT

        loop
            exitwhen (this == NULL)

            set this = this.$name$_next

            set iteration = iteration + 1
        endloop

        return iteration
    endmethod

    static method $name$_Amount takes nothing returns integer
        return (thistype.$name$_Count() - ARRAY_EMPTY)
    endmethod

    static method $name$_GetIndex takes thistype this returns integer
        local integer iteration

        if (thistype.$name$_Contains(this) == false) then
            return ARRAY_EMPTY
        endif

        set iteration = ARRAY_MIN

        loop
            set this = this.$name$_prev

            exitwhen (this == NULL)

            set iteration = iteration + 1
        endloop

        return iteration
    endmethod

    static method $name$_GetFirst takes nothing returns thistype
        return thistype.$name$_NEXT
    endmethod

    static method $name$_GetLast takes nothing returns thistype
        return thistype.$name$_LAST
    endmethod

    static method $name$_GetNext takes thistype this returns thistype
        return this.$name$_next
    endmethod

    static method $name$_GetPrev takes thistype this returns thistype
        return this.$name$_prev
    endmethod

    static method $name$_FetchFirst takes nothing returns thistype
        local thistype this = thistype.$name$_NEXT

        if (this == NULL) then
            return NULL
        endif

        set thistype.$name$_NEXT = this.$name$_next

        set this.$name$_next = NULL
        if (thistype.$name$_NEXT == NULL) then
            set thistype.$name$_LAST = NULL
        else
            set thistype.$name$_NEXT.$name$_prev = NULL
        endif

        return this
    endmethod

    static method $name$_Remove takes thistype this returns boolean
        local thistype next
        local thistype prev

        if (thistype.$name$_Contains(this) == false) then
            return false
        endif

        if (thistype.$name$_NEXT == this) then
            call thistype.$name$_FetchFirst()

            return thistype.$name$_IsEmpty()
        endif

        set next = this.$name$_next
        set prev = this.$name$_prev

        if (prev != NULL) then
            set this.$name$_prev = NULL
            set prev.$name$_next = next
        endif
        if (next == NULL) then
            set thistype.$name$_LAST = prev
        else
            set this.$name$_next = NULL
            set next.$name$_prev = prev
        endif

        return thistype.$name$_IsEmpty()
    endmethod

    static method $name$_Add takes thistype this returns boolean
        if thistype.$name$_Contains(this) then
            return false
        endif

        set this.$name$_next = NULL

        if (thistype.$name$_NEXT == NULL) then
            set thistype.$name$_LAST = this
            set thistype.$name$_NEXT = this

            return true
        endif

        set this.$name$_prev = thistype.$name$_LAST
        set thistype.$name$_LAST.$name$_next = this

        set thistype.$name$_LAST = this

        return false
    endmethod
//! endtextmacro

//! textmacro CreatePriorityQueue takes name
	static thistype array $name$_PRIOS
	static thistype array $name$_SUBS

	static integer array $name$_CUR_PRIO

	static method $name$_FetchFirst takes thistype this, integer prio returns thistype
		
	endmethod

	static method $name$_Remove takes thistype this, integer prio returns boolean
		if not thistype.$name$_ALL.Contains(this) then
			return false
		endif

		local Queue sub = thistype.$name$_SUBS[prio]

		call sub.Remove(this)

		set thistype.$name$_CUR_PRIO[this] = NULL
		call thistype.$name$_ALL.Remove(this)

		return true
	endmethod

	static method $name$_Add takes thistype this, integer prio returns boolean
		local Queue sub = thistype.$name$_SUBS[prio]

		if (sub == NULL) then
			set sub = Queue.Create()

			set thistype.$name$_SUBS[prio] = sub

			set thistype.$name$_PRIOS
		endif

		if thistype.$name$_ALL.Contains(this) then
			return false
		endif

		call sub.Add(this)

		set thistype.$name$_CUR_PRIO[this] = prio
		call thistype.$name$_ALL.Add(this)

		return true
	endmethod
//! endtextmacro

struct Queue
    implement Allocation
    //implement Name

    static key NEXT_KEY_ARRAY_DETAIL_BASE
    static key PREV_KEY_ARRAY_DETAIL_BASE

    static constant integer NEXT_KEY_ARRAY_DETAIL = thistype.NEXT_KEY_ARRAY_DETAIL_BASE * ARRAY_SIZE
    static constant integer PREV_KEY_ARRAY_DETAIL = thistype.PREV_KEY_ARRAY_DETAIL_BASE * ARRAY_SIZE

    integer first
    integer last

    method GetFirst takes nothing returns integer
        return this.first
    endmethod

    method GetLast takes nothing returns integer
        return this.last
    endmethod

    method GetNext takes integer el returns integer
        return Memory.IntegerKeys.GetInteger(el, NEXT_KEY_ARRAY_DETAIL + this)
    endmethod

    method GetPrev takes integer el returns integer
        return Memory.IntegerKeys.GetInteger(el, PREV_KEY_ARRAY_DETAIL + this)
    endmethod

    method IsEmpty takes nothing returns boolean
        return (this.GetFirst() == NULL)
    endmethod

    method Contains takes integer el returns boolean
        if (this.GetFirst() == el) then
            return true
        endif

        if ((this.GetPrev(el) != NULL) or (this.GetNext(el) != NULL)) then
            return true
        endif

        return false
    endmethod

    method Count takes nothing returns integer
        local integer iteration = ARRAY_EMPTY
        local integer el = this.GetFirst()

        loop
            exitwhen (el == NULL)

            set el = this.GetNext(el)

            set iteration = iteration + 1
        endloop

        return iteration
    endmethod

    method GetIndex takes integer el returns integer
        local integer iteration

        if (this.Contains(el) == false) then
            return ARRAY_EMPTY
        endif

        set iteration = ARRAY_MIN

        loop
            set el = this.GetPrev(el)

            exitwhen (el == NULL)

            set iteration = iteration + 1
        endloop

        return iteration
    endmethod

    method FetchFirst takes nothing returns integer
        local integer el = this.GetFirst()

        if (el == NULL) then
            return NULL
        endif

        set this.first = Memory.IntegerKeys.GetInteger(el, NEXT_KEY_ARRAY_DETAIL + this)

        call Memory.IntegerKeys.SetInteger(el, NEXT_KEY_ARRAY_DETAIL + this, NULL)
        if (this.GetFirst() == NULL) then
            set this.last = NULL
        else
            call Memory.IntegerKeys.SetInteger(this.GetFirst(), PREV_KEY_ARRAY_DETAIL + this, NULL)
        endif

        return el
    endmethod

    method Clear takes nothing returns nothing
        loop
            exitwhen (this.FetchFirst() == NULL)
        endloop
    endmethod

    method Remove takes integer el returns boolean
        local integer next
        local integer prev

        if (this.Contains(el) == false) then
            return false
        endif

        if (this.GetFirst() == el) then
            call this.FetchFirst()

            return this.IsEmpty()
        endif

        set next = Memory.IntegerKeys.GetInteger(el, NEXT_KEY_ARRAY_DETAIL + this)
        set prev = Memory.IntegerKeys.GetInteger(el, PREV_KEY_ARRAY_DETAIL + this)

        if (prev != NULL) then
            call Memory.IntegerKeys.SetInteger(el, PREV_KEY_ARRAY_DETAIL + this, NULL)
            call Memory.IntegerKeys.SetInteger(prev, NEXT_KEY_ARRAY_DETAIL + this, next)
        endif
        if (next == NULL) then
            set this.last = prev
        else
            call Memory.IntegerKeys.SetInteger(el, NEXT_KEY_ARRAY_DETAIL + this, NULL)
            call Memory.IntegerKeys.SetInteger(next, PREV_KEY_ARRAY_DETAIL + this, prev)
        endif

        return this.IsEmpty()
    endmethod

    method Add takes integer el returns boolean
        if this.Contains(el) then
            return false
        endif

        call Memory.IntegerKeys.SetInteger(el, NEXT_KEY_ARRAY_DETAIL + this, NULL)

        if this.IsEmpty() then
            set this.first = el
            set this.last = el

            return true
        endif

        call Memory.IntegerKeys.SetInteger(el, PREV_KEY_ARRAY_DETAIL + this, this.GetLast())
        call Memory.IntegerKeys.SetInteger(this.GetLast(), NEXT_KEY_ARRAY_DETAIL + this, el)

        set this.last = el

        return false
    endmethod

    method Print takes nothing returns nothing
        local integer el = this.GetFirst()

        call DebugEx("print queue " + I2S(this) + ":")

        loop
            exitwhen (el == NULL)

            call DebugEx("\t" + I2S(el))

            set el = this.GetNext(el)
        endloop

        call DebugEx("---")
    endmethod

    /*method Iterator takes nothing returns IteratorQueue
        return IteratorQueue.Create(this)
    endmethod*/

    method Destroy takes nothing returns nothing
        call this.Clear()

        call this.deallocate()
    endmethod

    static method Create takes nothing returns thistype
        local thistype this = thistype.allocate()

        set this.first = NULL
        set this.last = NULL

        return this
    endmethod
endstruct

/*struct IteratorQueue
    integer next

    method GetNext takes nothing returns integer
        local integer next = this.next

        set this.next = parent.GetNext(next)

        return next
    endmethod

    static method Create takes Queue parent returns thistype
        local thistype this = thistype.allocate()

        set this.next = parent.GetFirst()
        set this.parent = parent

        return this
    endmethod
endstruct*/

module Name
    static method Name takes nothing returns nothing
    endmethod

    static constant string NAME = "<" + thistype.Name.name + ">"

    static constant string NAME_SHORT = thistype.Name.name
endmodule

//! textmacro Struct takes name
    public struct Struct$name$
        implement Allocation
        implement List
        //implement Name
//! endtextmacro



//! textmacro BaseStruct takes name, base
    globals
        $name$ $base$ = STRUCT_BASE
    endglobals

    struct $name$
        implement Allocation
        implement List
        //implement Name
//! endtextmacro

//! textmacro StaticStruct takes name
    struct $name$
//! endtextmacro

//! textmacro CreateSimpleAddState_NotAdd takes type, defaultValue
    $type$ value

    method Get takes nothing returns $type$
        return this.value
    endmethod

    method Set takes $type$ value returns nothing
        set this.value = value
    endmethod

    method Event_Create takes nothing returns nothing
        call this.Set($defaultValue$)
    endmethod

    method Update takes nothing returns nothing
        call this.Set(this.Get())
    endmethod
//! endtextmacro

//! textmacro CreateSimpleAddState_NotStart takes type
    $type$ value

    method Get takes nothing returns $type$
        return this.value
    endmethod

    method Set takes $type$ value returns nothing
        set this.value = value
    endmethod

    method Add takes $type$ value returns nothing
        call this.Set(this.Get() + value)
    endmethod

    method Subtract takes $type$ value returns nothing
        call this.Set(this.Get() - value)
    endmethod

    method Update takes nothing returns nothing
        call this.Set(this.Get())
    endmethod
//! endtextmacro

//! textmacro CreateSimpleAddState_OnlyGet takes type
    $type$ value

    method Get takes nothing returns $type$
        return this.value
    endmethod
//! endtextmacro

//! textmacro CreateSimpleAddState_OnlyStart takes defaultValue
    method Event_Create takes nothing returns nothing
        set this.value = $defaultValue$
    endmethod
//! endtextmacro

//! textmacro CreateSimpleAddState_OnlyAdd takes type, defaultValue
    method Add takes $type$ value returns nothing
        call this.Set(this.Get() + value)
    endmethod

    method Event_Create takes nothing returns nothing
        call this.Set($defaultValue$)
    endmethod

    method Subtract takes $type$ value returns nothing
        call this.Set(this.Get() - value)
    endmethod

    method Update takes nothing returns nothing
        call this.Set(this.Get())
    endmethod
//! endtextmacro

//! textmacro CreateSimpleAddState_OnlyAddSub takes type
    method Add takes $type$ value returns nothing
        call this.Set(this.Get() + value)
    endmethod

    method Subtract takes $type$ value returns nothing
        call this.Set(this.Get() - value)
    endmethod
//! endtextmacro

//! textmacro CreateSimpleAddState_OnlyAdd_NotStart takes type
    method Add takes $type$ value returns nothing
        call this.Set(this.Get() + value)
    endmethod

    method Subtract takes $type$ value returns nothing
        call this.Set(this.Get() - value)
    endmethod

    method Update takes nothing returns nothing
        call this.Set(this.Get())
    endmethod
//! endtextmacro

//! textmacro CreateSimpleAddState_OnlyAdd_UsePreset takes type, presetValue, defaultValue
    method Add takes $type$ value returns nothing
        call this.Set(this.Get() + value)
    endmethod

    method Event_Create takes nothing returns nothing
        set this.value = $presetValue$
        call this.Set($defaultValue$)
    endmethod

    method Subtract takes $type$ value returns nothing
        call this.Set(this.Get() - value)
    endmethod

    method Update takes nothing returns nothing
        call this.Set(this.Get())
    endmethod
//! endtextmacro

//! textmacro CreateSimpleAddState_OnlyStart_UsePreset takes presetValue, defaultValue
    method Event_Create takes nothing returns nothing
        set this.value = $presetValue$
        call this.Set($defaultValue$)
    endmethod
//! endtextmacro

//! textmacro CreateSimpleAddState takes type, defaultValue
    $type$ value

    method Get takes nothing returns $type$
        return this.value
    endmethod

    method Set takes $type$ value returns nothing
        set this.value = value
    endmethod

    method Add takes $type$ value returns nothing
        call this.Set(this.Get() + value)
    endmethod

    method Event_Create takes nothing returns nothing
        call this.Set($defaultValue$)
    endmethod

    method Subtract takes $type$ value returns nothing
        call this.Set(this.Get() - value)
    endmethod

    method Update takes nothing returns nothing
        call this.Set(this.Get())
    endmethod
//! endtextmacro

//! textmacro CreateAnyFlagState takes varName, methodName
    boolean $varName$

    method Is$methodName$ takes nothing returns boolean
        return this.$varName$
    endmethod

    method Set$methodName$ takes boolean value returns nothing
        set this.$varName$ = value
    endmethod
//! endtextmacro

//! textmacro CreateAnyFlagStateDefault takes varName, methodName, default
    boolean $varName$ = $default$

    method Is$methodName$ takes nothing returns boolean
        return this.$varName$
    endmethod

    method Set$methodName$ takes boolean value returns nothing
        set this.$varName$ = value
    endmethod
//! endtextmacro

//! textmacro CreateAnyState takes varName, methodName, type
    $type$ $varName$

    method Get$methodName$ takes nothing returns $type$
        return this.$varName$
    endmethod

    method Set$methodName$ takes $type$ value returns nothing
        set this.$varName$ = value
    endmethod
//! endtextmacro

//! textmacro CreateAnyStateDefault takes varName, methodName, type, default
    $type$ $varName$

    method Get$methodName$ takes nothing returns $type$
        return this.$varName$
    endmethod

    method Set$methodName$ takes $type$ value returns nothing
        set this.$varName$ = value
    endmethod

	//! inject Allocation.allocate_mount.hook
		set this.$varName$ = $default$
	//! endinject
//! endtextmacro

//! textmacro CreateAnyStaticState takes varName, methodName, type
    static $type$ $varName$

    static method Get$methodName$ takes nothing returns $type$
        return thistype.$varName$
    endmethod

    static method Set$methodName$ takes $type$ value returns nothing
        set thistype.$varName$ = value
    endmethod
//! endtextmacro

//! textmacro CreateAnyStaticFlagState takes varName, methodName
    static boolean $varName$

    static method Is$methodName$ takes nothing returns boolean
        return thistype.$varName$
    endmethod

    static method Set$methodName$ takes boolean value returns nothing
        set thistype.$varName$ = value
    endmethod
//! endtextmacro

//! textmacro CreateAnyStaticStateDefault takes varName, methodName, type, default
    static $type$ $varName$ = $default$

    static method Get$methodName$ takes nothing returns $type$
        return thistype.$varName$
    endmethod

    static method Set$methodName$ takes $type$ value returns nothing
        set thistype.$varName$ = value
    endmethod
//! endtextmacro

//! textmacro CreateAnyStaticFlagStateDefault takes varName, methodName, default
    static boolean $varName$ = $default$

    static method Is$methodName$ takes nothing returns boolean
        return thistype.$varName$
    endmethod

    static method Set$methodName$ takes boolean value returns nothing
        set thistype.$varName$ = value
    endmethod
//! endtextmacro

//! textmacro CreateSimpleFlagState_NotStart
    boolean flag

    method Is takes nothing returns boolean
        return this.flag
    endmethod

    method Set takes boolean flag returns nothing
        set this.flag = flag
    endmethod
//! endtextmacro

//! textmacro CreateSimpleFlagState takes defaultValue
    boolean flag

    method Is takes nothing returns boolean
        return this.flag
    endmethod

    method Set takes boolean flag returns nothing
        set this.flag = flag
    endmethod

    method Event_Create takes nothing returns nothing
        call this.Set($defaultValue$)
    endmethod
//! endtextmacro

//! textmacro CreateSimpleFlagCountState takes defaultValue
    integer flag

    method Get takes nothing returns integer
        return this.flag
    endmethod

    method Is takes nothing returns boolean
        return (this.flag > 0)
    endmethod

    method Set takes integer flag returns nothing
        set this.flag = flag
    endmethod

    method Subtract takes nothing returns nothing
        call this.Set(this.Get() - 1)
    endmethod

    method SubtractValue takes integer value returns nothing
        call this.Set(this.Get() - value)
    endmethod

    method Add takes nothing returns nothing
        call this.Set(this.Get() + 1)
    endmethod

    method AddValue takes integer value returns nothing
        call this.Set(this.Get() + value)
    endmethod

    method Event_Create takes nothing returns nothing
        call this.Set($defaultValue$)
    endmethod
//! endtextmacro

//! textmacro CreateSimpleFlagCountState_NotStart
    integer flag

    method Get takes nothing returns integer
        return this.flag
    endmethod

    method Is takes nothing returns boolean
        return (this.flag > 0)
    endmethod

    method Set takes integer flag returns nothing
        set this.flag = flag
    endmethod

    method Subtract takes nothing returns nothing
        call this.Set(this.Get() - 1)
    endmethod

    method Add takes nothing returns nothing
        call this.Set(this.Get() + 1)
    endmethod
//! endtextmacro

//! textmacro CreateAnyFlagCountState takes name
    integer flag$name$

    method Get$name$ takes nothing returns integer
        return this.flag$name$
    endmethod

    method Is$name$ takes nothing returns boolean
        return (this.flag$name$ > 0)
    endmethod

    method Set$name$ takes integer value returns nothing
        set this.flag$name$ = value
    endmethod

    method Subtract$name$ takes nothing returns nothing
        call this.Set$name$(this.Get$name$() - 1)
    endmethod

    method SubtractValue$name$ takes integer value returns nothing
        call this.Set$name$(this.Get$name$() - value)
    endmethod

    method Add$name$ takes nothing returns nothing
        call this.Set$name$(this.Get$name$() + 1)
    endmethod

    method AddValue$name$ takes integer value returns nothing
        call this.Set$name$(this.Get$name$() + value)
    endmethod
//! endtextmacro

globals
    boolean TEMP_BOOLEAN
    boolean TEMP_BOOLEAN2
    boolean TEMP_BOOLEAN3
    boolean TEMP_BOOLEAN4
    integer TEMP_INTEGER
    integer TEMP_INTEGER2
    integer TEMP_INTEGER3
    integer TEMP_INTEGER4
    real TEMP_REAL
    real TEMP_REAL2
    real TEMP_REAL3
    real TEMP_REAL4
    real TEMP_REAL5
    real TEMP_REAL6
endglobals

globals
    boolean exit
endglobals

function Exit takes nothing returns boolean
    return exit
endfunction

function booleanToString takes boolean b returns string
    if (b) then
        return "true"
    endif

    return "false"
endfunction

function integerToString takes integer a returns string
    return I2S(a)
endfunction

function realToString takes real a returns string
    return R2S(a)
endfunction

function stringToString takes string s returns string
    return s
endfunction

function Print takes string s returns nothing
    call DisplayTextToPlayer(GetLocalPlayer(), 0., 0., s)
endfunction

function RenderGraphics takes nothing returns nothing
    //call PauseGame(true)

    //call Trigger.Sleep(0.)

    //call PauseGame(false)
endfunction

/*//! externalblock extension=lua ObjectMerger $FILENAME$
    //! i setobjecttype("doodads")

    //! i modifyobject("D02G")

    //! i makechange(current, "dfil", "Doodads\\Grass\\Grass")
//! endexternalblock*/

struct ObjThread
    implement Allocation
    implement List
    //implement Name

    static timer CHECK_TIMER = null

    string name

    method AddMark takes string value returns nothing
        set this.name = this.name + ";" + value
    endmethod

    method Destroy takes nothing returns nothing
        call this.deallocate()

        if this.RemoveFromList() then
            call PauseTimer(thistype.CHECK_TIMER)
        endif
    endmethod

    static method PrintErrors takes nothing returns nothing
        local integer i = thistype.ALL_COUNT

		call DebugBufferStart()

        loop
            exitwhen (i < ARRAY_MIN)

            call DebugBuffer("threadBreak (ObjThread): " + thistype.ALL[i].name)
set DEBUG_EX_ON = false
            call thistype.ALL[i].Destroy()
set DEBUG_EX_ON = true
            set i = i - 1
        endloop

		call DebugBufferFinish()
    endmethod

    static method Create takes string name returns thistype
        local thistype this = thistype.allocate()

        set this.name = name

        if this.AddToList() then
            if (thistype.CHECK_TIMER == null) then
                set thistype.CHECK_TIMER = CreateTimer()
            endif

            call TimerStart(thistype.CHECK_TIMER, 1, true, function thistype.PrintErrors)
        endif

        return this
    endmethod

    static method CreateEx takes string name returns thistype
        call InfoEx("init: " + name)

        return thistype.Create(name)
    endmethod
endstruct