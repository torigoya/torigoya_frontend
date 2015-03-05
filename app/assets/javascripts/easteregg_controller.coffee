class AOJJudgeStatus
    constructor: (data) ->
        if data
            @update(data)
        @isDummy = data == null

    update: (data) =>
        @accuracy = data.accuracy
        @code = data.code
        @contestID = data.contestID
        @cputime = data.cputime
        @judgeDate = data.judgeDate
        @judgeType = data.judgeType
        @lang = data.lang
        @lessonID = data.lessonID
        @memory = data.memory
        @problemID = data.problemID
        @problemTitle = data.problemTitle
        @runID = data.runID
        @score = data.score
        @status = data.status
        @submissionDate = data.submissionDate
        @userID = data.userID

    getId: () =>
        if @lessonID.length == 0 then @problemID else "#{@lessonID}_#{@problemID}"

    getStatusStyle: () =>
        switch @status
            when 0 then "danger"    # Compile Error
            when 1 then "danger"    # Wrong Answer
            when 2 then "warning"   # Time Limit Exceeded
            when 3 then "warning"   # Memory Limit Exceeded
            when 4 then "success"   # Accepted
            when 5 then "info"      # Waiting Judge
            when 6 then "warning"   # Output Limit Exceeded
            when 7 then "danger"    # Runtime Error
            when 8 then "warning"   # Presentation Error
            when 9 then "info"      # Running
            when -1 then "active"   # Judge Not Available
            else "active"

    getStatusString: () =>
        switch @status
            when 0 then "CE"    # Compile Error
            when 1 then "WA"    # Wrong Answer
            when 2 then "TLE"   # Time Limit Exceeded
            when 3 then "MLE"   # Memory Limit Exceeded
            when 4 then "AC"    # Accepted
            when 5 then "W"     # Waiting Judge
            when 6 then "OLE"   # Output Limit Exceeded
            when 7 then "RE"    # Runtime Error
            when 8 then "PE"    # Presentation Error
            when 9 then "Run.." # Running
            when -1 then "NA"   # Judge Not Available
            else "-"


@ProcGardenApp.controller(
    'EasterEggController',
    ['$scope', '$rootScope', ($scope, $rootScope) =>
        $scope.showingPopup = false

        $scope.togglePopup = () =>
            $scope.showingPopup = !$scope.showingPopup

        $scope.aoj = {
            init: (() =>
                AOJ.livestatus ((event, isError) =>
                    unless isError
                        s = JSON.parse event.data
                        if s.userID != $scope.aoj.userId
                            return

                        $rootScope.$apply () =>
                            unless s.runID of $scope.aoj.statusWithRunID
                                stat = new AOJJudgeStatus(s)
                                $scope.aoj.statusWithRunID[s.runID] = stat
                                $scope.aoj.status.push stat
                                if $scope.aoj.status.length >= 5
                                    $scope.aoj.status.shift()
                            else
                                stat = $scope.aoj.statusWithRunID[s.runID]
                                stat.update s
                )
            ),

            submit: (() =>
                langId = $scope.aoj.language.enum
                source = (new @CodemirrorEditor).get_value()

                AOJ.submit($scope.aoj.userId, $scope.aoj.password, $scope.aoj.problemNo, $scope.aoj.lessonId, langId, source)
                    .done (data) =>
                        dom = $($.parseHTML(data))
                        result = dom.filter('result')

                        if result.length != 0
                            # there is the result, so it maybe error
                            resultXML = $($.parseHTML(result.html()))
                            succeeded = resultXML.filter('succeeded')[0].innerText == 'true'
                            message = resultXML.filter('message')[0].innerText
                            unless succeeded
                                # error
                                alert message

                    .fail () =>
                        alert 'Failed to submit a source to AOJ...'
            ),

            userId: "",
            password: "",
            problemNo: "",
            lessonId: "",
            languages: AOJ.LanguageString.map((s, i) => {title: s, enum: i}),
            language: {},

            status: (new AOJJudgeStatus(null) for _ in [1..5]),
            statusWithRunID: {}
        }
    ]
)
