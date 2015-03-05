/// <reference path="typings/jquery/jquery.d.ts"/>
/// <reference path="../../../vendor/assets/bower_components/reconnectingWebsocket/reconnecting-websockets.d.ts"/>

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

    function langEnumToString(e: Language) {
        var str = [
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

        return str[e];
    }

    class Submit {
        static ENDPOINT = 'http://judge.u-aizu.ac.jp/onlinejudge/servlet/Submit';
    }

    export function submit(
        userId: string,
        password: string,
        problemId: number,
        lang: Language,
        source: string
    ) {
        console.log('aoj submit!');

        $.post(Submit.ENDPOINT, {
            userID: userId,
            password: password,
            problemNO: problemId,
            language: langEnumToString(lang),
            sourceCode: source,
        }).done((data: any) => {
            alert( "Data Loaded: " + data );
        }).fail(() => {
            alert('Failed to submit a source to AOJ...');
        });

        //var ws = new ReconnectingWebSocket('ws://....');
    }


    class StatusStreem {
        static ENDPOINT = 'ws://ionazn.org/status';
    }

    export function livestatus(userId: string, callback: ()=>void) {
        var ws = new ReconnectingWebSocket(StatusStreem.ENDPOINT);
        ws.onmessage = (event: any) => {
            console.log(event);
        };
        ws.onerror = (event: ErrorEvent) => {
            console.error(event);
        };
        return ws;
    }
}

(() => {
    var src = 'import std.stdio; \
    void main() { "Hello World".writeln; }';

    AOJ.livestatus('', null);
})();