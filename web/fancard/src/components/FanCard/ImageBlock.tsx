import Image from "next/image";
import { ImageBlockData } from "@/types/fancard";

interface ImageBlockProps {
  data: ImageBlockData;
}

export default function ImageBlock({ data }: ImageBlockProps) {
  const ImageWrapper = data.linkUrl ? "a" : "div";
  const wrapperProps = data.linkUrl
    ? {
        href: data.linkUrl,
        target: "_blank",
        rel: "noopener noreferrer",
      }
    : {};

  return (
    <ImageWrapper
      {...wrapperProps}
      className="block rounded-xl overflow-hidden shadow-sm hover:shadow-md transition-shadow"
    >
      <div className="relative aspect-square bg-gray-100">
        <Image
          src={data.imageUrl}
          alt={data.caption || "Image"}
          fill
          className="object-cover"
        />
      </div>
      {data.caption && (
        <div className="p-3 bg-white">
          <p className="text-sm text-gray-600 text-center">{data.caption}</p>
        </div>
      )}
    </ImageWrapper>
  );
}
