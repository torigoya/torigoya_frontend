class @CodemirrorEditor
    constructor: (option) ->
        @name = "sc-code-editor"

        window.torigoya = {} unless window.hasOwnProperty('torigoya')
        window.torigoya.editor = {} unless window.torigoya.hasOwnProperty('editor')
        window.torigoya.editor[@name] = {} unless window.torigoya.editor.hasOwnProperty(@name)

        @dissable_rich_editor_flag = window.torigoya?.editor[@name]?.dissable_rich_editor ? false

        @option = option if option?

        @_reset_editor()


    get_value: () =>
        return if @dissable_rich_editor_flag then $(@_get_editor_dom()).val() else @editor.doc.getValue()


    set_value: (s) =>
        if s?
            if @dissable_rich_editor_flag then $(@_get_editor_dom()).val(s) else @editor.doc.setValue(s)


    set_font_size: (font_size_px) =>
        window.torigoya.editor[@name].font_size_px = font_size_px
        $(@_get_editor_dom()).css('font-size', font_size_px)
        @dom?.css('font-size', font_size_px)
        @editor?.refresh()

    set_tab_or_space: (indent_type) =>
        window.torigoya.editor[@name].indent_type = indent_type
        @editor?.setOption('indentWithTabs', indent_type == 'tab')
        @editor?.refresh()

    set_indent_size: (indent_size) =>
        window.torigoya.editor[@name].indent_size = indent_size

        indent_size = parseInt(indent_size, 10) unless indent_size instanceof Number
        @editor?.setOption('tabSize', indent_size);
        @editor?.setOption('indentUnit', indent_size);
        @editor?.refresh()

    set_keybind: (keybind) =>
        window.torigoya.editor[@name].keybind = keybind
        @editor?.setOption('keyMap', keybind)
        @editor?.refresh()

    set_theme: (theme) =>
        window.torigoya.editor[@name].theme = theme
        @editor?.setOption("theme", theme)
        @editor?.refresh()


    set_highlight: (language_title) =>
        unless language_title?
            return

        window.torigoya.editor[@name].language_title = language_title
        lang =
            if (/^c\+\+/i.test(language_title))
                { mime: "text/x-c++src", mode: "clike" }
            else if (/^python/i.test(language_title))
                { mime: "text/x-python", mode: "python" }
            else if (/^javascript/i.test(language_title))
                { mime: "text/javascript", mode: "javascript" }
            else if (/^java/i.test(language_title))
                { mime: "text/x-java", mode: "clike" }
            else if (/^ruby/i.test(language_title))
                { mime: "text/x-ruby", mode: "ruby" }
            else if (/^ocaml/i.test(language_title))
                { mime: "text/x-ocaml", mode: "mllike" }
            else if (/^d/i.test(language_title))
                { mime: "text/x-d", mode: "d" }
            else if (/^c/i.test(language_title))
                { mime: "text/x-csrc", mode: "clike" }
            else
                console.log "editor_highlight: #{language_title} is not supported"
                null

        unless lang?
            return

        ## http://codemirror.net/mode/
        # console.log "@sc_change_editor_highlight: #{lang.mime}"
        # apl.js
        # asterisk.js
        # clike.js
        # clojure.js
        # cobol.js
        # coffeescript.js
        # commonlisp.js
        # css.js
        # diff.js
        # d.js
        # ecl.js
        # erlang.js
        # gas.js
        # gfm.js
        # go.js
        # groovy.js
        # haml.js
        # haskell.js
        # haxe.js
        # htmlembedded.js
        # htmlmixed.js
        # http.js
        # jade.js
        # javascript.js
        # jinja2.js
        # less.js
        # livescript.js
        # lua.js
        # markdown.js
        # mirc.js
        # nginx.js
        # ntriples.js
        # ocaml.js
        # pascal.js
        # perl.js
        # php.js
        # pig.js
        # properties.js
        # python.js
        # q.js
        # r.js
        # rpm-changes.js
        # rpm-spec.js
        # rst.js
        # ruby.js
        # rust.js
        # sass.js
        # scheme.js
        # scss_test.js
        # shell.js
        # sieve.js
        # smalltalk.js
        # smarty.js
        # smartymixed.js
        # sparql.js
        # sql.js
        # stex.js
        # tcl.js
        # tiddlywiki.js
        # tiki.js
        # turtle.js
        # vb.js
        # vbscript.js
        # velocity.js
        # verilog.js
        # xml.js
        # xquery.js
        # yaml.js
        # z80.js

        # set to CodeMirror Editor
        @editor?.setOption("mode", lang.mime)
        CodeMirror.autoLoadMode(@editor, lang.mode) if @editor?

        @editor?.refresh()


    ########################################
    #
    set_dissable_rich_editor_flag: (do_dissable) =>
        @dissable_rich_editor_flag = do_dissable
        window.torigoya.editor[@name].dissable_rich_editor = do_dissable

        @_reset_editor(true, true)


    ########################################
    #
    reconfig: () =>
        if @dissable_rich_editor_flag
            return

        @set_font_size(window.torigoya.editor[@name].font_size_px)
        @set_tab_or_space( window.torigoya.editor[@name].indent_type)
        @set_indent_size(window.torigoya.editor[@name].indent_size)
        @set_keybind(window.torigoya.editor[@name].keybind)
        @set_theme(window.torigoya.editor[@name].theme)
        @set_highlight(window.torigoya.editor[@name].language_title)


    ########################################
    #
    _reset_editor: (do_force_reset = false, do_reset_without_size = false) =>
        p = $('.CodeMirror')
        # if .Codemirror exists, restore...
        if p.length == 0
            unless @dissable_rich_editor_flag
                # create new CodeMirror object
                CodeMirror.modeURL = "/assets/codemirror/modes/%N.js";
                @editor = CodeMirror.fromTextArea(@_get_editor_dom())
                @dom = $('.CodeMirror')

                # save object
                window.torigoya_editor_object = {} unless window.hasOwnProperty('torigoya_editor_object')
                window.torigoya_editor_object[@name] = @editor

                #
                do_force_reset = true

        else
            # restore from saved object...
            unless @dissable_rich_editor_flag
                @editor = window.torigoya_editor_object[@name]
                @dom = $('.CodeMirror')
            else
                @editor?.toTextArea()

        # load options
        if @option?
            window.torigoya_editor_option = {} unless window.hasOwnProperty('torigoya_editor_option')
            window.torigoya_editor_option[@name] = @option
        else
            @option = window.torigoya_editor_option[@name]

        @_apply_options(do_force_reset, do_reset_without_size)


    _apply_options: (do_force_reset, do_reset_without_size) =>
        unless do_force_reset
            return

        # set options
        if @option?
            editor_config = {
                width: "100%",
                height: "100%",
                lineNumbers: true,
                styleActiveLine: true,
                lineWrapping: true,
                matchBrackets: true,
                viewportMargin: Infinity,
                readOnly: if @option?.readonly? then @option.readonly else false
                extraKeys: {
                    Tab: @_code_mirror_extra_tab
                }
            }
            for keymap, f of @option?.extra_key
                editor_config.extraKeys[keymap] = f

            for k, v of editor_config
                @editor?.setOption(k, v)

            #
            if do_reset_without_size
                #$(@_get_editor_dom()).width(window.torigoya.editor[@name].width).height(window.torigoya.editor[@name].height)
                #@editor?.setSize(window.torigoya.editor[@name].width, window.torigoya.editor[@name].height)
                1
            else
                raw_dom = $(@_get_editor_dom())

                #if @option?.height?
                #    raw_dom.height(@option.height)
                #    @editor?.setSize(null, @option.height)

                if @option?.readonly
                    raw_dom.attr({ readonly: "readonly" })

                window.torigoya.editor[@name].width = if @dom? then @dom.width() else raw_dom.width() unless window.torigoya.editor[@name].width?
                window.torigoya.editor[@name].height = if @dom? then @dom.height() else raw_dom.height() unless window.torigoya.editor[@name].height?

            @editor?.refresh()


    _get_editor_dom: () =>
        return document.getElementById("sc-code-editor")

    _code_mirror_extra_tab: (cm) =>
        if (cm.somethingSelected())
            cm.indentSelection("add")

        else
            cursor = cm.getCursor()
            indent_width = parseInt(cm.getOption("indentUnit"), 10)
            width_array = ((if ch == '\t' then indent_width else 1) for ch in cm.getLine(cursor.line)[0...cursor.ch])
            current_position = if width_array.length == 0 then 0 else (width_array.reduce (x,y) -> x + y)
            result_length = if (current_position % indent_width == 0) then indent_width else (indent_width - current_position % indent_width)

            cm.replaceSelection(
                (if cm.getOption("indentWithTabs") then "\t" else (Array(result_length + 1).join(' '))),
                "end",
                "+input"
                )
