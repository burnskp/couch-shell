// Slow fixture makes hide cancellation observable before the report arrives.
setTimeout(() => {
	console.log(
		JSON.stringify({
			version: 1,
			status: "ok",
			collectedAt: Date.now(),
			filesystems: [
				{
					uuid: "test-volume",
					label: "cryptroot",
					device: "/dev/mapper/cryptroot",
					status: "ok",
					accounting: "valid",
					availableBytes: 1024,
					totalBytes: 2048,
					subvolumes: Array.from({ length: 80 }, (_, i) => ({
						id: i + 256,
						path: `subvolume-${i}`,
						uuid: `uuid-${i}`,
						parentUuid: null,
						referencedBytes: 1024,
						exclusiveBytes: 0,
					})),
				},
			],
		}),
	);
}, 500);
