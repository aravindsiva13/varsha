exports.download = async (req, res) => {
  try {
    console.log("Sending file...");
    res.download("excel_templates/sample.xlsx", (err) => {
      if (err) {
        console.error("Download failed:", err);
        return res.status(500).json({ error: "Error while sending the file." });
      }
      console.log("File sent successfully");
    });

  } catch (err) {
    console.error("Download error:", err);
    res.status(500).json({ 
      error: "Internal server error", 
      details: err.message 
    });
  }
};
