import axios from 'axios'

const lighthouseNode = 'https://node.lighthouse.storage';

export async function uploadToLighthouse(apiKey, buffer) {
  try {
    const token = 'Bearer ' + apiKey
    const endpoint = lighthouseNode + '/api/v0/add'

    // Upload file
    const formData = new FormData()
    formData.append('file', buffer)

    const response = await axios.post(endpoint, formData, {
      // withCredentials: true,
      maxContentLength: Infinity, //this is needed to prevent axios from erroring out with large directories
      maxBodyLength: Infinity,
      headers: {
        Encryption: 'false',
        'Mime-Type': 'application/pdf',
        Authorization: token,
        body: formData
      },
    })

    return { data: response.data }
  } catch (error) {
    throw new Error(error?.message)
  }
}

