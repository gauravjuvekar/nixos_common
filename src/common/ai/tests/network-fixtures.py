"""Local HTTPS, HTTP, and DNS fixtures for the package's sandboxed checks."""

import http.server
import pathlib
import signal
import socket
import socketserver
import ssl
import struct
import sys
import threading

IPV4 = "192.0.2.1"
IPV6 = "2001:db8::1"
BODY = b"vey-network-fixture\n"


def question(name):
    labels = b"".join(bytes([len(label)]) + label.encode() for label in name.split("."))
    return struct.pack("!6H", 1234, 0x100, 1, 0, 0, 0) + labels + b"\0\0\1\0\1"


def udp_probe():
    query = question("connectivity.test")
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as client:
        client.settimeout(2)
        client.sendto(query, (IPV4, 53))
        response, _ = client.recvfrom(4096)
    assert response[:2] == query[:2]
    assert struct.unpack("!H", response[2:4])[0] & 0x800F == 0x8000
    assert response.endswith(socket.inet_aton(IPV4))


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Length", str(len(BODY)))
        self.end_headers()
        self.wfile.write(BODY)

    def log_message(self, *_args):
        pass


class IPv6HTTPServer(http.server.ThreadingHTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
        super().server_bind()


class DNSHandler(socketserver.BaseRequestHandler):
    def handle(self):
        packet, transport = self.request
        end = 12
        labels = []
        while packet[end]:
            length = packet[end]
            labels.append(packet[end + 1 : end + 1 + length].decode())
            end += length + 1
        end += 1
        name = ".".join(labels).lower()
        kind, _ = struct.unpack("!HH", packet[end : end + 4])
        private = name in {"private.test", "localhost"}
        address = {1: "127.0.0.1" if private else IPV4, 28: "::1" if private else IPV6}.get(kind)
        answer = b""
        if address:
            family = socket.AF_INET if kind == 1 else socket.AF_INET6
            value = socket.inet_pton(family, address)
            answer = struct.pack("!HHHIH", 0xC00C, kind, 1, 30, len(value)) + value
        header = packet[:2] + struct.pack("!5H", 0x8180, 1, bool(answer), 0, 0)
        transport.sendto(header + packet[12 : end + 4] + answer, self.client_address)


def serve(cert, key, ready):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(cert, key)
    servers = [socketserver.ThreadingUDPServer(("0.0.0.0", 53), DNSHandler)]
    for server_type, address in [(http.server.ThreadingHTTPServer, "0.0.0.0"), (IPv6HTTPServer, "::")]:
        for port in (80, 443):
            server = server_type((address, port), Handler)
            if port == 443:
                server.socket = context.wrap_socket(server.socket, server_side=True)
            servers.append(server)
    for server in servers:
        threading.Thread(target=server.serve_forever, daemon=True).start()
    pathlib.Path(ready).touch()
    signal.pause()


if __name__ == "__main__":
    if sys.argv[1] == "serve":
        serve(*sys.argv[2:])
    elif sys.argv[1] == "udp-probe":
        udp_probe()
    else:
        raise SystemExit("Expected serve or udp-probe")
