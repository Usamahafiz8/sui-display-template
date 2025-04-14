import { Transaction } from "@mysten/sui/transactions";
import { SuiClient } from "@mysten/sui/client";
import { bcs } from "@mysten/sui/bcs";
import { SUI_NETWORK, getSigner } from "./config";
import dotenv from "dotenv";

dotenv.config();

const client = new SuiClient({
  url: SUI_NETWORK,
});

export type DisplayFieldsType = {
  keys: string[];
  values: string[];
};

export async function createDisplay() {
  try {
    console.log("Using network:", SUI_NETWORK);

    const tx = new Transaction();
    const signer = await getSigner();
    const signerAddress = signer.toSuiAddress();
    console.log("Signer address:", signerAddress);

    let displayObject: DisplayFieldsType = {
      keys: [
        "name",
        "image_url",
        "description",
        "project_url",
        "creator",
        "intellectual_property",
        "category",
      ],
      values: [
        " non Transferable NFT",
        "A public POAP NFT for event participation",
        "osamaa",
        "POAP",
        "POAP",
      ],
    };

    const publisherID = "0x8b0ad67846206b9da03a2fce6c3664b8729f6d3d88c3d534f03e7cd3d912b6ff";
    const packageID = "0x02a8676313f9dc91c8b037ad5363479294f49a358df5d416ab9a0023a5749dc8";
    console.log("Using publisherID:", publisherID);
    console.log("Using packageID:", packageID);

    tx.setGasBudget(20000000);
    console.log("Gas budget set to 20,000,000 MIST");

    let display = tx.moveCall({
      target: "0x2::display::new_with_fields",
      arguments: [
        tx.object(publisherID),
        tx.pure(bcs.vector(bcs.string()).serialize(displayObject.keys)),
        tx.pure(bcs.vector(bcs.string()).serialize(displayObject.values)),
      ],
      typeArguments: [`${packageID}::souv_event::Public<${packageID}::souv_event::osamanft1>`],
    });
    console.log("Called new_with_fields for Public struct");

    tx.moveCall({
      target: "0x2::display::update_version",
      arguments: [display],
      typeArguments: [`${packageID}::souv_event::Public<${packageID}::souv_event::osamanft1>`],
    });
    console.log("Called update_version");

    tx.transferObjects([display], signerAddress);
    console.log("Transferred Display object to signer");

    console.log("Executing transaction...");
    const result = await client.signAndExecuteTransaction({
      transaction: tx,
      signer: signer,
      options: {
        showEffects: true,
        showObjectChanges: true,
        showEvents: true,
        showInput: true,
      },
    });

    console.log("Transaction result:", JSON.stringify(result, null, 2));

    if (result.effects?.status.status !== "success") {
      throw new Error(`Transaction failed: ${result.effects?.status.error}`);
    }

    console.log("Created objects:", result.effects?.created);
    console.log("Object changes:", result.objectChanges);

    const displayId = result.effects?.created?.find(
      // @ts-ignore
      (obj) => obj.owner === "Immutable" || typeof obj.owner === "object" || obj.owner.AddressOwner === signerAddress
    )?.reference.objectId;

    if (!displayId) {
      throw new Error("Failed to retrieve Display object ID");
    }

    console.log(`Display created successfully with ID: ${displayId}`);
    return displayId;
  } catch (error) {
    console.error("Error creating display:", error);
    throw error;
  }
}

createDisplay().catch((err) => {
  console.error("Failed to create display:", err);
});