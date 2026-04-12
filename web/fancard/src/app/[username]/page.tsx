import { Metadata } from "next";
import { notFound } from "next/navigation";
import { getFanCardByOdDisplayName } from "@/lib/api";
import FanCardView from "@/components/FanCard/FanCardView";
import ViewCounter from "@/components/FanCard/ViewCounter";

interface PageProps {
  params: Promise<{ username: string }>;
}

/**
 * Generate metadata for the page (OGP)
 */
export async function generateMetadata({
  params,
}: PageProps): Promise<Metadata> {
  const resolvedParams = await params;
  const username = decodeURIComponent(resolvedParams.username);
  const data = await getFanCardByOdDisplayName(username);

  if (!data) {
    return {
      title: "FanCard Not Found",
      description: "This FanCard does not exist or is not public.",
    };
  }

  const { fanCard, myBias } = data;

  // Build description from bias info
  let description = fanCard.bio || "";
  if (myBias && myBias.length > 0) {
    const biasNames = myBias
      .map((b) => {
        const members = b.memberNames.join(", ");
        return members ? `${b.artistName} (${members})` : b.artistName;
      })
      .join(" / ");
    description = description
      ? `${description} | ${biasNames}`
      : `${biasNames}推し`;
  }

  const baseUrl =
    process.env.NEXT_PUBLIC_BASE_URL || "https://oshipick.com";

  return {
    title: `${fanCard.displayName}のFanCard`,
    description: description || `${fanCard.displayName}のFanCard`,
    openGraph: {
      title: `${fanCard.displayName}のFanCard`,
      description: description || `${fanCard.displayName}のFanCard`,
      url: `${baseUrl}/${username}`,
      siteName: "K-VOTE COLLECTOR FanCard",
      images: [
        {
          url: `${baseUrl}/${username}/opengraph-image`,
          width: 1200,
          height: 630,
          alt: `${fanCard.displayName}のFanCard`,
        },
      ],
      type: "profile",
    },
    twitter: {
      card: "summary_large_image",
      title: `${fanCard.displayName}のFanCard`,
      description: description || `${fanCard.displayName}のFanCard`,
      images: [`${baseUrl}/${username}/opengraph-image`],
    },
  };
}

/**
 * FanCard Public Page
 */
export default async function FanCardPage({ params }: PageProps) {
  const resolvedParams = await params;
  const username = decodeURIComponent(resolvedParams.username);

  const data = await getFanCardByOdDisplayName(username);

  if (!data) {
    notFound();
  }

  return (
    <>
      <FanCardView data={data} />
      <ViewCounter odDisplayName={username} />
    </>
  );
}
