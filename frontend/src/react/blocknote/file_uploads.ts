export async function uploadFileToServer(file: File, attachmentsUploadUrl: string) {
  const body = prepareInitialRequest(file);
  body.append('file', file);

  const ret = await fetch(`${attachmentsUploadUrl}`, {
    method: 'POST',
    body: body,
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
    },
  });
  return (await ret.json())._links.staticDownloadLocation.href;
}

export async function uploadFileToStorage(file: File, attachmentsUploadUrl: string) {
  // First, the "prepare" endpoint is called to get the upload URL.
  const prepareBody = prepareInitialRequest(file);
  const prepare = await fetch(`${attachmentsUploadUrl}`, {
    method: 'POST',
    body: prepareBody,
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
    },
  });
  const prepareResponseJson = await prepare.json();
  // Then, with the information from the "prepare" endpoint, the actual upload is done.
  const uploadFormData = prepareUploadRequest(prepareResponseJson, file);
  const uploadResponse = await fetch(prepareResponseJson._links.addAttachment.href, {
    method: 'POST',
    body: uploadFormData,
  });
  // TODO: ERROR HANDLING!!!???
  // If the upload succeeds, the "complete" endpoint is called to finish the upload.
  const uploadFinishedResponse = await fetch(prepareResponseJson._links.completeUpload.href, {
    method: 'GET',
  });
  const uploadFinishedResponseJson = await uploadFinishedResponse.json();

  // Finally, the URL of the newly uploaded file is returned so it can be used by the editor.
  return uploadFinishedResponseJson._links.staticDownloadLocation.href;
}

function prepareInitialRequest(file: File){
  const metadata = {
    fileName: file.name,
    contentType: file.type,
    fileSize: file.size,
  };
  const body = new FormData();
  body.append('metadata', JSON.stringify(metadata));

  return body;
}

function prepareUploadRequest(prepareResponseJson: any, file: File){
  const uploadFormData = new FormData();
  // TODO: Write my own interface for prepareResponse ?! So I can safely access the form fields?
  const formFields = prepareResponseJson._links.addAttachment.form_fields;
  for (const key in formFields) {
    uploadFormData.append(key, formFields[key]);
  }
  uploadFormData.append('file', file);

  return uploadFormData;
}
