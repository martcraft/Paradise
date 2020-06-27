//Bureaucracy machine!
//Simply set this up in the hopline and you can serve people based on ticket numbers

/obj/machinery/ticket_machine
	name = "ticket machine"
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "ticketmachine"
	desc = "A marvel of bureaucratic engineering encased in an efficient plastic shell. It can be refilled with a hand labeler refill roll and linked to buttons with a multitool."
	density = FALSE
	maptext_height = 26
	maptext_width = 32
	maptext_x = 7
	maptext_y = 10
	layer = HIGH_OBJ_LAYER
	var/ticket_number = 0 //Increment the ticket number whenever the HOP presses his button
	var/current_number = 0 //What ticket number are we currently serving?
	var/max_number = 100 //At this point, you need to refill it.
	var/cooldown = 50
	var/ready = TRUE
	var/list/ticket_holders = list()
	var/list/tickets = list()
	var/id = 1

/obj/machinery/ticket_machine/Destroy()
	if(tickets)
		for(var/ticket in tickets)
			var/obj/item/ticket_machine_ticket/T = ticket
			T.visible_message("<span class='notice'>\the [ticket] disperses!</span>")
			qdel(T)
		tickets.Cut()
	ticket_holders.Cut()
	return ..()

/obj/machinery/ticket_machine/emag_act(mob/user) //Emag the ticket machine to dispense burning tickets, as well as randomize its number to destroy the HoP's mind.
	if(emagged)
		return
	to_chat(user, "<span class='warning'>You overload [src]'s bureaucratic logic circuitry to its MAXIMUM setting.</span>")
	ticket_number = rand(0, max_number)
	current_number = ticket_number
	emagged = TRUE
	if(length(tickets))
		for(var/obj/item/ticket_machine_ticket/ticket in tickets)
			ticket.visible_message("<span class='notice'>\the [ticket] disperses!</span>")
			qdel(ticket)
		tickets.Cut()
	update_icon()

/obj/machinery/ticket_machine/Initialize(mapload)
	. = ..()
	update_icon()

/obj/machinery/ticket_machine/proc/increment()
	if(current_number > ticket_number)
		return
	if(current_number && !(emagged) && tickets[current_number])
		var/obj/item/ticket_machine_ticket/ticket = tickets[current_number]
		ticket.audible_message("<span class='notice'>\the [tickets[current_number]] vibrates!</span>")
		qdel(tickets[current_number])
	if(current_number < ticket_number)
		current_number ++ //Increment the one we're serving.
		playsound(src, 'sound/misc/announce_dig.ogg', 50, FALSE)
		atom_say("Now serving ticket #[current_number]!")
		if(!(emagged) && tickets[current_number])
			var/obj/item/ticket_machine_ticket/ticket = tickets[current_number]
			ticket.audible_message("<span class='notice'>\the [tickets[current_number]] vibrates!</span>")
		update_icon() //Update our icon here rather than when they take a ticket to show the current ticket number being served

/obj/machinery/door_control/ticket_machine_button
	name = "increment ticket counter"
	desc = "Use this button after you've served someone to tell the next person to come forward."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "doorctrl0"
	req_access = list()
	id = 1
	var/cooldown = FALSE


/obj/machinery/door_control/ticket_machine_button/attack_hand(mob/user)
	if(allowed(usr) || user.can_advanced_admin_interact())
		for(var/obj/machinery/ticket_machine/M in GLOB.machines)
			if(M.id == id)
				if(cooldown)
					return
				cooldown = TRUE
				M.increment()
				addtimer(VARSET_CALLBACK(src, cooldown, FALSE), 10)
	else
		to_chat(usr, "<span class='warning'>Access denied.</span>")


/obj/machinery/ticket_machine/update_icon()
	switch(ticket_number) //Gives you an idea of how many tickets are left
		if(0 to 49)
			icon_state = "ticketmachine_100"
		if(50 to 99)
			icon_state = "ticketmachine_50"
		if(100)
			icon_state = "ticketmachine_0"
	handle_maptext()

/obj/machinery/ticket_machine/proc/handle_maptext()
	switch(ticket_number) //This is here to handle maptext offsets so that the numbers align.
		if(0 to 9)
			maptext_x = 13
		if(10 to 99)
			maptext_x = 10
		if(100)
			maptext_x = 8
	maptext = "[current_number]" //Finally, apply the maptext

/obj/machinery/ticket_machine/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/hand_labeler_refill))
		if(!(ticket_number >= max_number))
			to_chat(user, "<span class='notice'>[src] refuses [I]! There [max_number-ticket_number==1 ? "is" : "are"] still [max_number-ticket_number] ticket\s left!</span>")
			return
		to_chat(user, "<span class='notice'>You start to refill [src]'s ticket holder (doing this will reset its ticket count!).</span>")
		if(do_after(user, 30, target = src))
			to_chat(user, "<span class='notice'>You insert [I] into [src] as it whirs nondescriptly.</span>")
			user.drop_item()
			qdel(I)
			ticket_number = 0
			current_number = 0
			if(tickets)
				for(var/ticket in tickets)
					var/obj/item/ticket_machine_ticket/T = ticket
					T.visible_message("<span class='notice'>\the [ticket] disperses!</span>")
					qdel(T)
				tickets.Cut()
			max_number = initial(max_number)
			update_icon()
			return
	else
		return ..()

/obj/machinery/ticket_machine/proc/reset_cooldown()
	ready = TRUE

/obj/machinery/ticket_machine/attack_hand(mob/living/carbon/user)
	. = ..()
	if(!ready)
		to_chat(user,"<span class='warning'>You press the button, but nothing happens...</span>")
		return
	if(ticket_number >= max_number)
		to_chat(user,"<span class='warning'>Ticket supply depleted, please refill this unit with a hand labeller refill cartridge!</span>")
		return
	if((user in ticket_holders) && !(emagged))
		to_chat(user, "<span class='warning'>You already have a ticket!</span>")
		return
	playsound(src, 'sound/machines/terminal_insert_disc.ogg', 100, FALSE)
	ticket_number ++
	to_chat(user, "<span class='notice'>You take a ticket from [src], looks like you're ticket number #[ticket_number]...</span>")
	var/obj/item/ticket_machine_ticket/theirticket = new /obj/item/ticket_machine_ticket(get_turf(src))
	theirticket.name = "Ticket #[ticket_number]"
	theirticket.maptext = "<font color='#000000'>[ticket_number]</font>"
	theirticket.saved_maptext = "<font color='#000000'>[ticket_number]</font>"
	theirticket.ticket_number = ticket_number
	theirticket.source = src
	theirticket.owner = user
	user.put_in_hands(theirticket)
	ticket_holders += user
	tickets += theirticket
	if(emagged) //Emag the machine to destroy the HOP's life.
		ready = FALSE
		addtimer(CALLBACK(src, .proc/reset_cooldown), cooldown)//Small cooldown to prevent piles of flaming tickets
		theirticket.fire_act()
		user.drop_item()
		user.adjust_fire_stacks(1)
		user.IgniteMob()

/obj/item/ticket_machine_ticket
	name = "Ticket"
	desc = "A ticket which shows your place in the Head of Personnel's line. Made from Nanotrasen patented NanoPaper®. Though solid, its form seems to shimmer slightly. Feels (and burns) just like the real thing."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "ticket"
	maptext_x = 7
	maptext_y = 10
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	max_integrity = 50
	var/saved_maptext = null
	var/mob/living/carbon/owner
	var/obj/machinery/ticket_machine/source
	var/ticket_number

/obj/item/ticket_machine_ticket/attack_hand(mob/user)
	. = ..()
	maptext = saved_maptext //For some reason, storage code removes all maptext off objs, this stops its number from being wiped off when taken out of storage.

/obj/item/ticket_machine_ticket/attackby(obj/item/P, mob/living/carbon/human/user, params) //Stolen from papercode
	..()
	if(is_hot(P))
		if((CLUMSY in user.mutations) && prob(10))
			user.visible_message("<span class='warning'>[user] accidentally ignites [user.p_them()]self!</span>", \
								"<span class='userdanger'>You miss the paper and accidentally light yourself on fire!</span>")
			user.drop_item()
			user.adjust_fire_stacks(1)
			user.IgniteMob()
			return
		user.visible_message("<span class='danger'>[user] lights [src] ablaze with [P]!</span>", "<span class='danger'>You light [src] on fire!</span>")
		fire_act()

/obj/item/paper/extinguish()
	..()
	update_icon()

/obj/item/ticket_machine_ticket/Destroy()
	if(owner && source)
		source.ticket_holders -= owner
		source.tickets[ticket_number] = null
		owner = null
		source = null
	return ..()
