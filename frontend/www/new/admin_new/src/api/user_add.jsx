import { testConfig } from '.././test.jsx';


export async function createUser(user) {
  let url = `${testConfig.user}services/user.cgi?method=create_user`;
  url += `&email=${user.email}`;
  url += `&first_name=${user.firstName}`;
  url += `&last_name=${user.lastName}`;
  url += `&username=${user.username}`;

  const resp = await fetch(url, {method: 'get', credentials: 'include'});
  const data = await resp.json();
  if (data.error_text) throw data.error_text;
  return data.results[0];
}

let path = testConfig.user;
async function addUser(user_id, first_name, family_name, email_address, type, status, auth_name) {
    let url = `${path}services/admin/admin.cgi?method=add_user&user_id=${user_id}&first_name=${first_name}&family_name=${family_name}&email_address=${email_address}&type=${type}&status=${status}&auth_name=${auth_name}`;

    try {
        const resp = await fetch(url, { method: 'get', credentials: 'include' });
        const data = await resp.json();
        if (data.error_text) throw data.error_text;
        return data.results;
    } catch (error) {
        console.log('Failure occurred in addUser.');
        console.log(error);
        return [];
    }
}
export default addUser;
