import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Rewrite root path to serve static HTML
  if (pathname === "/") {
    return NextResponse.rewrite(new URL("/oshipick/index.html", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/"],
};
