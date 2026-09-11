import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Zim Tuckshop",
  description: "African foods, everyday essentials and family favourites.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
