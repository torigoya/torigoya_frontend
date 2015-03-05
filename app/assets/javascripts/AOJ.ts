/// <reference path="typings/jquery/jquery.d.ts"/>
/// <reference path="reconnecting-websockets.d.ts"/>

module AOJ {
    export enum Language {
        C,
        Cplusplus,
        Java,
        Cplusplus11,
        Csharp,
        D,
        Ruby,
        Python,
        Python3,
        PHP,
        JavaScript,
    }

    export var LanguageString: Array<string> = [
        'C',
        'C++',
        'JAVA',
        'C++11',
        'C#',
        'D',
        'Ruby',
        'Python',
        'Python3',
        'PHP',
        'JavaScript',
    ];

    export function langEnumToString(e: Language) {
        return LanguageString[e];
    }

    class Submit {
        static ENDPOINT = 'http://judge.u-aizu.ac.jp/onlinejudge/webservice/submit';
    }

    export function submit(
        userId: string,
        password: string,
        problemId: string,
        lessonId: string,
        lang: Language,
        source: string
    ) {
        return $.ajax({
            type: 'POST',
            url: Submit.ENDPOINT,
            data: {
                userID: userId,
                password: password,
                problemNO: problemId,
                lessonID: lessonId,
                language: langEnumToString(lang),
                sourceCode: source,
            },
            dataType: 'html'
        });
    }


    class StatusStreem {
        static ENDPOINT = 'ws://ionazn.org/status';
    }

    export function livestatus(callback: (e: any, isError: boolean)=>void) {
        var ws = new ReconnectingWebSocket(StatusStreem.ENDPOINT);
        if (callback) {
            ws.onmessage = (event: CustomEvent) => {
                callback(event, false);
            };
            ws.onerror = (event: ErrorEvent) => {
                callback(event, true);
            };
        }

        return ws;
    }
}