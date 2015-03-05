@ProcGardenApp.controller(
    'SourceCodeEditor',
    ['$scope', ($scope) =>
        #
        $scope.font_size = {
            current: $.cookie("sc-editor-font-size") ? "13px",
            list: ("#{num}px" for num in [8..20])
        }
        $scope.$watchCollection(
            'font_size.current',
            ()=>
                $.cookie("sc-editor-font-size", $scope.font_size.current)
                (new @CodemirrorEditor).set_font_size($scope.font_size.current)
        )

        #
        $scope.tab_or_space = {
            current: $.cookie("sc-editor-tab-or-space") ? "space",
            list: [
                "tab",
                "space"
            ]
        }
        $scope.$watchCollection(
            'tab_or_space.current',
            ()=>
                $.cookie("sc-editor-tab-or-space", $scope.tab_or_space.current)
                (new @CodemirrorEditor).set_tab_or_space($scope.tab_or_space.current)
        )

        #
        $scope.indent_size = {
            current: $.cookie("sc-editor-indent-size") ? "4",
            list: [
                "2",
                "4",
                "8"
            ]
        }
        $scope.$watchCollection(
            'indent_size.current',
            ()=>
                $.cookie("sc-editor-indent-size", $scope.indent_size.current)
                (new @CodemirrorEditor).set_indent_size($scope.indent_size.current)
        )

        #
        $scope.keybind = {
            current: $.cookie("sc-editor-keybind") ? "default",
            list: [
                "default",
                "emacs",
                "vim"
            ]
        }
        $scope.$watchCollection(
            'keybind.current',
            ()=>
                $.cookie("sc-editor-keybind", $scope.keybind.current)
                (new @CodemirrorEditor).set_keybind($scope.keybind.current)
        )

        #
        $scope.theme = {
            current: $.cookie("sc-editor-theme") ? "eclipse",
            list: [
                "default",
                "ambiance",
                "blackboard",
                "cobalt",
                "eclipse",
                "elegant",
                "erlang-dark",
                "lesser-dark",
                "monokai",
                "neat",
                "night",
                "rubyblue",
                "twilight",
                "vibrant-ink",
                "xq-dark",
            ]
        }
        $scope.$watchCollection(
            'theme.current',
            ()=>
                $.cookie("sc-editor-theme", $scope.theme.current)
                (new @CodemirrorEditor).set_theme($scope.theme.current)
        )


        #
        $scope.dissable_rich_editor = if $.cookie("sc-editor-dissable-rich-editor") then $.cookie("sc-editor-dissable-rich-editor") == 'true' else false
        $scope.$watchCollection(
            'dissable_rich_editor',
            ()=>
                $.cookie("sc-editor-dissable-rich-editor", if $scope.dissable_rich_editor then 'true' else 'false')

                editor = new @CodemirrorEditor
                editor.set_dissable_rich_editor_flag($scope.dissable_rich_editor)
                editor.reconfig()
        )



        $scope.is_option_collapsed = $.cookie("sc-editor-is-option-collapsed") == 'true'

        $scope.toggleOptionCollapse = () =>
            console.log "aaaa"

            $scope.is_option_collapsed = !$scope.is_option_collapsed
            $.cookie("sc-editor-is-option-collapsed", $scope.is_option_collapsed.toString())

    ]
)
