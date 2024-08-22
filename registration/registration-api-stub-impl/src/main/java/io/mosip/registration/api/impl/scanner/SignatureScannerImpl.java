package io.mosip.registration.api.impl.scanner;

import java.io.IOException;
import java.security.SignatureException;
import java.util.List;

import org.springframework.stereotype.Component;

import io.mosip.registration.api.signaturescanner.SignatureService;
import io.mosip.registration.api.signaturescanner.constant.StreamType;
import io.mosip.registration.dto.ScanDevice;

@Component
public class SignatureScannerImpl implements SignatureService {

	@Override
	public String getServiceName() {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public void scan(ScanDevice docScanDevice, String deviceType) throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	public void retry() throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	public void cancel() throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	public void confirm() throws Exception {
		// TODO Auto-generated method stub

	}

	@Override
	public byte[] loadData(StreamType streamType) throws SignatureException, IOException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public List<ScanDevice> getConnectedDevices() throws Exception {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public void stop(ScanDevice docScanDevice) {
		// TODO Auto-generated method stub

	}

}
