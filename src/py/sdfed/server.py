from extra import Service, HTTPRequest, HTTPResponse, on, run
from extra.services.files import FileService
from pathlib import Path
from .evaluator import render


# TODO: We should really create a sanbox using Nix and then run the code in ther

# class SDF:
#
#     @classmethod
#     def Eval( cls, code:str ) ->

class API(Service):
    @on(GET_POST="/api/mesh")
    async def mesh(self, request: HTTPRequest) -> HTTPResponse:
        await request.load()
        print("MESH", request.body)
        return request.respond(b"Hello, World !", b"text/plain")


if __name__ == "__main__":
    run(FileService(Path(".")), API())

# EOF
