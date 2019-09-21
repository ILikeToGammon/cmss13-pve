var/datum/subsystem/chat/SSchat

/datum/subsystem/chat
	name = "Chat"
	flags = SS_TICKER
	wait = 1
	priority = SS_PRIORITY_CHAT
	init_order = SS_INIT_CHAT

	var/list/chatQueue = list()


/datum/subsystem/chat/New()
	NEW_SS_GLOBAL(SSchat)

/datum/subsystem/chat/fire()
	for(var/i in chatQueue)
		var/client/C = i
		C << output(chatQueue[C], "browseroutput:output")
		chatQueue -= C

		if(MC_TICK_CHECK)
			return

/datum/subsystem/chat/proc/queue(var/target, var/message)
	if(!target || !message)
		return

	if(!istext(message))
		CRASH("to_chat called with invalid input type")
		return

	if(target == world)
		target = clients

	var/clean_message = message
	//Some macros remain in the string even after parsing and fuck up the eventual output
	message = replacetext(message, "`", "")
	message = replacetext(message, "\improper", "")
	message = replacetext(message, "\proper", "")
	message = replacetext(message, "\n", "<br>")
	message = replacetext(message, "\t", "["&nbsp;&nbsp;&nbsp;&nbsp;"]["&nbsp;&nbsp;&nbsp;&nbsp;"]")
	message += "<br>"

	var/encoded_message = url_encode(url_encode(message))

	//Grab us a client if possible
	if(islist(target))
		#define GCHAT_UNDEFINED_LIST 0
		#define GCHAT_CLIENT_LIST 1
		#define GCHAT_MOB_LIST 2
		#define GCHAT_MIND_LIST 3
		var/type_of_list = GCHAT_UNDEFINED_LIST
		for(var/T in target)
			var/client/C

			if(GCHAT_UNDEFINED_LIST)
				if (istype(T, /client))
					type_of_list = GCHAT_CLIENT_LIST
				else if (istype(T, /mob))
					type_of_list = GCHAT_MOB_LIST
				else if (istype(T, /datum/mind))
					type_of_list = GCHAT_MIND_LIST
				else
					continue
			
			if(type_of_list == GCHAT_CLIENT_LIST)
				C = T
			
			if(type_of_list == GCHAT_MOB_LIST)
				var/mob/M = T
				if(!istype(M))
					continue
				C = M.client
			
			if(type_of_list == GCHAT_MOB_LIST)
				var/datum/mind/M = T
				if(!istype(M))
					continue
				if(M.current)
					C = M.current.client

			if(!C || !istype(C))
				continue

			// If they are using the old chat, send it the old way
			if(C.chatOutput && C.chatOutput.oldChat || !C.chatOutput)
				C << clean_message
				continue
			
			if (C.chatOutput && !C.chatOutput.loaded && C.chatOutput.messageQueue && islist(C.chatOutput.messageQueue))
				//Client sucks at loading things, put their messages in a queue
				C.chatOutput.messageQueue += message
				continue

			chatQueue[C] += encoded_message
		#undef GCHAT_UNDEFINED_LIST
		#undef GCHAT_CLIENT_LIST
		#undef GCHAT_MOB_LIST
		#undef GCHAT_MIND_LIST
	else
		var/client/C
		if (istype(target, /client))
			C = target
		else if (istype(target, /mob))
			C = target:client
		else if (istype(target, /datum/mind) && target:current)
			C = target:current:client

		if(!C || !istype(C))
			return

		if(C.chatOutput && C.chatOutput.oldChat || !C.chatOutput)
			C << clean_message
			return

		if (C.chatOutput && !C.chatOutput.loaded && C.chatOutput.messageQueue && islist(C.chatOutput.messageQueue))
			C.chatOutput.messageQueue += message
			return

		chatQueue[C] += encoded_message