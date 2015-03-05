# ==================================================
# ==================================================
# ==================================================
# ==================================================
# TicketsController
@ProcGardenApp.controller(
    'EntryController',
    ['$scope', '$rootScope', '$sce', ($scope, $rootScope, $sce) =>
        $scope.do_save_cookie = true

        $scope.mark_as_not_saving_cookie = () =>
            $scope.do_save_cookie = false

        $scope.create_proc_list = () ->
            # gon.proc_table is set by controller
            # data type is hash and defined in torigoya cage

            # initialize
            init = ProcGarden.Procs.initial_set(gon.proc_table);

            $scope.procs = init.procs
            $scope.procs_group = init.group

        # Language Processor List...
        $scope.procs = []
        $scope.procs_group = {}
        $scope.create_proc_list()

        #
        $scope.submit_able = true
        $scope.is_running = false

        #
        $scope.current_entry_id = null
        $scope.current_entry_tweet = null
        $scope.current_entry_target_url = ""

        #
        $scope.visibility = if $.cookie("sc-entry-visibility") then parseInt($.cookie("sc-entry-visibility")) else @VisibilityProtected
        $scope.$watch(
            'visibility',
            (new_value)=>
                unless new_value?
                    return

                if $scope.do_save_cookie
                    $.cookie("sc-entry-visibility", new_value)
        )

        $scope.tickets = []

        ########################################
        # Tab index of Ticket
        $scope.selected_tab_index = 0
        $scope.selected_ticket = null

        $scope.change_ticket_tab = (index) =>
            $scope.selected_tab_index = index
            $scope.selected_ticket = $scope.tickets[index]

        $scope.remove_ticket_tab = (index) =>
            if !$scope.is_ticket_tab_removable
                return

            $scope.tickets.splice(index, 1);    # remove the element

            new_index = if $scope.selected_tab_index >= index then $scope.selected_tab_index - 1 else $scope.selected_tab_index
            $scope.change_ticket_tab(new_index)

        $scope.is_ticket_tab_removable = (index) =>
            $scope.tickets.length > 1 && !$scope.is_running

        ########################################
        # Tab index of Inputs
        $scope.selected_input_tab_index = 0
        $scope.selected_input = null

        $scope.change_input_tab = (index) =>
            $scope.selected_input_tab_index = index
            $scope.selected_input = $scope.selected_ticket.inputs[index]


        ########################################
        # change editor highlight by selected item
        $scope.$watch(
            'selected_ticket.data.selected_proc_id',
            (new_id, old_id) =>
                # console.log old_value, new_value
                unless new_id?
                    $scope.submit_able = false
                    return
                $scope.submit_able = true

                # new_proc: ProcGarden.Proc
                new_proc = $scope.procs[new_id]
                (new @CodemirrorEditor).set_highlight(new_proc.title)

                if $scope.do_save_cookie
                    $.cookie("sc-editor-cached-language-title", new_proc.title)

                selected_ticket = $scope.tickets[$scope.selected_tab_index]
                unless selected_ticket?
                    return
                old_proc = selected_ticket.current_proc

                selected_ticket.change_proc(new_proc, false)

                if new_proc.id != old_proc.id
                    selected_ticket.refresh_command_lines()
        )


        #
        $scope.$watchCollection(
            'selected_ticket.compile.cmd_args.structured.selected_data',
            (new_value)=>
                unless new_value?
                    return

                ticket = $scope.tickets[$scope.selected_tab_index]
                ticket.compile.cmd_args.structured.save($scope.do_save_cookie)
        )

        #
        $scope.$watchCollection(
            'selected_ticket.link.cmd_args.structured.selected_data',
            (new_value)=>
                unless new_value?
                    return

                ticket = $scope.tickets[$scope.selected_tab_index]
                ticket.link.cmd_args.structured.save($scope.do_save_cookie)
        )

        #
        $scope.$watchCollection(
            '$scope.selected_input.cmd_args.structured.selected_data',
            (new_value)=>
                unless new_value?
                    return

                ticket = $scope.tickets[$scope.selected_tab_index]
                input = ticket.inputs[$scope.selected_input_tab_index]
                input.cmd_args.structured.save($scope.do_save_cookie)
        )

        ########################################
        #
        $scope.append_ticket = () =>
            for ticket in $scope.tickets
                ticket.tab_ui.inactivate()

            # type: ProcGarden.Proc
            default_proc = ProcGarden.Procs.select_default($scope.procs)

            # ticket format
            ticket = new ProcGarden.Ticket(default_proc)
            $scope.tickets.push(ticket)

            # the ticket must has inputs at least one.
            ticket.append_input()

        $scope.is_ticket_appendable = () =>
            # number of inputs must be [1, 10]
            $scope.tickets.length < 10 && !$scope.is_running

        ########################################
        #
        $scope.force_set_ticket_tab_index = (ticket_index) =>
            for ticket in $scope.tickets
                ticket.tab_ui.inactivate()
            $scope.tickets[ticket_index].tab_ui.activate()
            $scope.change_ticket_tab(ticket_index)


        ########################################
        #
        $scope.append_input = (ticket_index) =>
            $scope.tickets[ticket_index].append_input()


        ########################################
        $scope.reset_entry = () =>
            for ticket, ticket_index in $scope.tickets
                $scope.tickets[ticket_index].reset()




        ########################################
        # phase 1
        $scope.submit_all = () =>
            $scope.is_running = true
            $scope.reset_entry()

            # console.log "submit all!"
            source_code = (new @CodemirrorEditor).get_value()
            # console.log source_code

            # !!!! construct POST data
            raw_submit_data = {
                description: "",
                visibility: $scope.visibility,
                source_codes: [
                    source_code
                ],
                tickets: ({
                    proc_id: ticket.current_proc.value.proc_id,
                    proc_version: ticket.current_proc.value.proc_version,
                    do_execution: ticket.do_execution,
                    compile: {
                        structured_command_line: ticket.compile.cmd_args.structured.to_valarray(),
                    },
                    link: {
                        structured_command_line: ticket.link.cmd_args.structured.to_valarray(),
                    },
                    inputs: ({
                        structured_command_line: input.cmd_args.structured.to_valarray(),
                        command_line: input.cmd_args.freed,
                        stdin: input.stdin
                    } for input in ticket.inputs)
                } for ticket in $scope.tickets)
            }

            submit_data = {
                api_version: 1,
                type: "json",
                value: JSON.stringify(raw_submit_data)
            }
            # console.log "submit => ", submit_data

            # submit!
            $.post("/api/system/source", submit_data, "json")
                .done (data) =>
                    $rootScope.$apply () =>
                        if data.is_error
                            alert("Error[1](please report): #{data.message}")
                            $scope.finish_ticket()
                        else
                            $scope.wait_entry_for_update(data.entry_id)
                .fail () =>
                    $rootScope.$apply () =>
                        alert("Failed[1]")
                        $scope.finish_ticket()


        ########################################
        # phase 2
        $scope.wait_entry_for_update = (entry_id, with_init = false) =>
            $scope.is_running = true

            $.get("/api/system/entry/#{entry_id}", "json")
                .done (data) =>
                    $rootScope.$apply () =>
                        if data.is_error
                            alert("Error[2](please report): #{data.message}")
                            $scope.finish_ticket()
                        else
                            ticket_ids = data.ticket_ids

                            if !with_init
                                $scope.current_entry_id = entry_id

                                # make parmlink button
                                $scope.current_entry_target_url = "http://sc.yutopp.net/entries/#{$scope.current_entry_id}"
                                text = "[ProcGarden]⊂二二二（ ◔⊖◔）二⊃"
                                tweet_url = "https://platform.twitter.com/widgets/tweet_button.html?url=#{$scope.current_entry_target_url}&text=#{text}"
                                $scope.current_entry_tweet = $sce.trustAsResourceUrl(tweet_url)

                            # console.log "Entry Loaded: " + JSON.stringify(data)

                            if with_init
                                # make tickets
                                $scope.tickets = []
                                # console.log "ticket_ids", ticket_ids
                                for i in [0...(ticket_ids.length)]
                                    $scope.append_ticket()
                                $scope.force_set_ticket_tab_index(0)

                                # load source code
                                $scope.visibility = data.entry.visibility

                            # console.log data.ticket.num
                            # apply for all tickets
                            ticket_ids.forEach((ticket_id) =>
                                # set processing flag
                                # $scope.tickets[i].is_processing = true
                                # make handler for get ticket data per ticket
                                $scope.wait_ticket_for_update(ticket_id, with_init)
                            )

                .fail () =>
                    $rootScope.$apply () =>
                        alert("Failed[2]")
                        $scope.finish_ticket(ticket_index)


        ########################################
        # phase 3
        $scope.wait_ticket_for_update = (ticket_id, with_init = false, ticket_index = null) =>
            # console.log "wait_ticket_for_update=>", ticket_id

            submit_data = {
                api_version: 1,
                type: "json"
            }
            if ticket_index?
                target_ticket = $scope.tickets[ticket_index]
                raw_submit_data = target_ticket.recieved_until()
                submit_data.value = JSON.stringify(raw_submit_data)

            # console.log "submit => ", submit_data

            $.get("/api/system/ticket/#{ticket_id}", submit_data, "json")
                .done (data) =>
                    # console.log( "Data Loaded: " + JSON.stringify(data) )
                    $rootScope.$apply () =>
                        if data.is_error
                            alert("Error[3](please report): #{data.message}")
                            $scope.finish_ticket()
                        else
                            console.log data

                            ticket_model = data.ticket
                            ticket_index = ticket_model.index
                            # console.log "Ticket Loaded: " + JSON.stringify(ticket_model)

                            if with_init
                                $scope.load_ticket_profile(ticket_index, ticket_model)

                            #
                            $scope.tickets[ticket_index].update(ticket_model)

                            # console.log "ticket", ticket_index, ticket_model

                            if ticket_model["is_running"]
                                # set processing flag
                                $scope.tickets[ticket_index].is_processing = true
                                if $scope.selected_tab_index == ticket_index
                                    setTimeout( (() => $scope.wait_ticket_for_update(ticket_id, false, ticket_index) ), 200 ) # recursive call
                                else
                                    setTimeout( (() => $scope.wait_ticket_for_update(ticket_id, false, ticket_index) ), 2000 ) # recursive call
                            else
                                # set processing flag
                                $scope.finish_ticket(ticket_index)
                .fail () =>
                    $rootScope.$apply () =>
                        alert("Failed[3]")
                        $scope.finish_ticket()


        ########################################
        $scope.finish_ticket = (ticket_index) =>
            f = (i) =>
                $scope.tickets[i].is_processing = false
                for input, index in $scope.tickets[i].inputs
                    $scope.tickets[i].inputs[index].is_running = false

            if ticket_index?
                f(ticket_index)
            else
                for ticket, index in $scope.tickets
                    f(index)

            $scope.is_running = false
            for ticket, index in $scope.tickets
                $scope.is_running |= ticket.is_processing


        ########################################
        #
        $scope.load_ticket_profile = (ticket_index, ticket_model) =>
            proc_id = ticket_model.proc_id
            proc_version = ticket_model.proc_version

            ticket = $scope.tickets[ticket_index]
            found_proc = ProcGarden.Procs.fallback($scope.procs, proc_id, proc_version, ticket, ticket_model)

            #
            ticket.change_proc(found_proc)

            # inputs number error correction
            if ticket_model.run_states?
                ticket.inputs = []
                for i in ticket_model.run_states
                    ticket.append_input()

            #
            ticket.refresh_command_lines()
            ticket.load_init_data_from_model(ticket_model)




    ]
)








# ==================================================
# ==================================================
# ==================================================
# ==================================================
#
ProcGardenApp.controller(
    'RunnerNodeAddresses',
    ['$scope', ($scope) =>
        $scope.nodes = @sc_g_runner_table
    ]
)





# ==================================================
# ==================================================
#

# ==================================================
# ==================================================
# ==================================================



# ==================================================
# Editor Settngs
# ==================================================
# Ready
@sc_setup_editor = (option = {}) ->
    window.torigoya = {}
    new @CodemirrorEditor(option)
