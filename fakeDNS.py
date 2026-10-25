from dnslib import *
from dnslib.server import *

class FakeDNS(BaseResolver):
    def resolve(self, request, handler):
        reply = request.reply()
        reply.add_answer(RR(
            request.q.qname,
            QTYPE.A,
            rdata=A("192.168.1.13"),
            ttl=60
        ))
        return reply

resolver = FakeDNS()
server = DNSServer(resolver, port=53, address="0.0.0.0")
server.start_thread()
print("Fake DNS running on port 53...")
input("Press Enter to stop...\n")
